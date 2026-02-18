import Foundation
import CloudKit
import Combine
import os

@MainActor
class DrinkSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    private let cloudProvider: any CloudProvider
    private let recordIDsKey = "DrinkEntryRecordIDs"
    private let lastSyncKey = "LastDrinkSyncDate"
    private let deletedEntriesKey = "DeletedDrinkEntryIDs"

    // Maps entry UUID to cloud record ID
    private var recordIDs: [UUID: String] = [:]

    // Track locally deleted entries to sync deletions
    private var deletedEntryIDs: Set<UUID> = []

    init(cloudProvider: any CloudProvider) {
        self.cloudProvider = cloudProvider
        loadRecordIDs()
        loadDeletedEntryIDs()
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Full Sync

    /// Performs a full sync: fetches from cloud, merges with local, uploads changes
    func performFullSync(localEntries: [DrinkEntry]) async throws -> [DrinkEntry] {
        guard cloudProvider.isAvailable else {
            return localEntries
        }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        // 1. Fetch all entries from cloud (may fail on first sync, that's OK)
        let cloudEntries = await fetchAllFromCloudSafe()

        // 2. Sync deletions to cloud
        do {
            try await syncDeletionsToCloud()
        } catch {
            AppLogger.sync.error("Deletion sync failed: \(error.localizedDescription)")
            // Continue with sync, track error but don't fail completely
        }

        // 3. Merge local and cloud entries
        let merged = mergeEntries(local: localEntries, cloud: cloudEntries)

        // 4. Upload new/modified local entries, tracking failures
        var uploadErrors: [Error] = []
        for entry in merged.toUpload {
            do {
                try await uploadEntry(entry)
            } catch {
                AppLogger.sync.error("Failed to upload entry \(entry.id): \(error.localizedDescription)")
                uploadErrors.append(error)
            }
        }

        // 5. Set sync error if any uploads failed
        if !uploadErrors.isEmpty {
            syncError = SyncError.partialFailure(
                successCount: merged.toUpload.count - uploadErrors.count,
                failureCount: uploadErrors.count
            )
        }

        // 6. Update last sync date
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

        return merged.result
    }

    /// Custom sync error type
    enum SyncError: LocalizedError {
        case partialFailure(successCount: Int, failureCount: Int)
        case networkUnavailable
        case cloudKitError(Error)

        var errorDescription: String? {
            switch self {
            case .partialFailure(let success, let failure):
                return "Synced \(success) items, \(failure) failed"
            case .networkUnavailable:
                return "Network unavailable"
            case .cloudKitError(let error):
                return error.localizedDescription
            }
        }
    }

    private func fetchAllFromCloudSafe() async -> [DrinkEntry] {
        do {
            return try await fetchAllFromCloud()
        } catch {
            AppLogger.sync.error("Cloud fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Individual Operations

    /// Upload a single new entry
    func uploadEntry(_ entry: DrinkEntry) async throws {
        guard cloudProvider.isAvailable else { return }

        let record = entry.toCloudRecord()
        let saved = try await cloudProvider.saveToPrivate(record)
        recordIDs[entry.id] = saved.recordID
        saveRecordIDs()
    }

    /// Update an existing entry
    func updateEntry(_ entry: DrinkEntry) async throws {
        guard cloudProvider.isAvailable else { return }

        if let recordName = recordIDs[entry.id] {
            let record = entry.toCloudRecord(existingRecordID: recordName)
            try await cloudProvider.saveToPrivate(record)
        } else {
            // Entry not yet synced, upload it
            try await uploadEntry(entry)
        }
    }

    /// Delete an entry from cloud
    func deleteEntry(_ entry: DrinkEntry) async throws {
        guard cloudProvider.isAvailable else { return }

        if let recordName = recordIDs[entry.id] {
            try await cloudProvider.deleteFromPrivate(recordID: recordName)
            recordIDs.removeValue(forKey: entry.id)
            saveRecordIDs()
        }

        // Remove from deleted tracking
        deletedEntryIDs.remove(entry.id)
        saveDeletedEntryIDs()
    }

    /// Mark an entry as deleted (for syncing deletion later)
    func markAsDeleted(_ entryID: UUID) {
        deletedEntryIDs.insert(entryID)
        saveDeletedEntryIDs()
    }

    // MARK: - Cloud Operations

    private func fetchAllFromCloud() async throws -> [DrinkEntry] {
        do {
            let records = try await cloudProvider.fetchFromPrivate(recordType: DrinkEntry.recordType)

            var entries: [DrinkEntry] = []
            for record in records {
                if let entry = DrinkEntry(from: record) {
                    entries.append(entry)
                    recordIDs[entry.id] = record.recordID
                }
            }
            saveRecordIDs()

            return entries
        } catch {
            // If fetch fails (e.g., schema not set up), return empty and let uploads create schema
            AppLogger.sync.debug("Fetch from cloud failed (normal on first sync): \(error.localizedDescription)")
            return []
        }
    }

    private func syncDeletionsToCloud() async throws {
        for entryID in deletedEntryIDs {
            if let recordName = recordIDs[entryID] {
                do {
                    try await cloudProvider.deleteFromPrivate(recordID: recordName)
                } catch {
                    // Ignore errors for records that may already be deleted
                }
                recordIDs.removeValue(forKey: entryID)
            }
        }
        deletedEntryIDs.removeAll()
        saveDeletedEntryIDs()
        saveRecordIDs()
    }

    private func uploadEntries(_ entries: [DrinkEntry]) async throws {
        for entry in entries {
            try await uploadEntry(entry)
        }
    }

    // MARK: - Merge Logic

    private struct MergeResult {
        let result: [DrinkEntry]      // Final merged list
        let toUpload: [DrinkEntry]    // Entries that need uploading
    }

    private func mergeEntries(local: [DrinkEntry], cloud: [DrinkEntry]) -> MergeResult {
        var result: [UUID: DrinkEntry] = [:]
        var toUpload: [DrinkEntry] = []

        // Add all cloud entries first
        for entry in cloud {
            // Skip entries that were deleted locally
            if !deletedEntryIDs.contains(entry.id) {
                result[entry.id] = entry
            }
        }

        // Merge local entries
        for entry in local {
            if let cloudEntry = result[entry.id] {
                // Entry exists in both - keep the newer one
                if entry.timestamp > cloudEntry.timestamp {
                    result[entry.id] = entry
                    toUpload.append(entry)
                }
                // If cloud is newer, we already have it in result
            } else {
                // Entry only exists locally - add it and mark for upload
                result[entry.id] = entry
                if !recordIDs.keys.contains(entry.id) {
                    toUpload.append(entry)
                }
            }
        }

        return MergeResult(
            result: Array(result.values).sorted { $0.timestamp > $1.timestamp },
            toUpload: toUpload
        )
    }

    // MARK: - Local Storage

    private func loadRecordIDs() {
        if let data = UserDefaults.standard.data(forKey: recordIDsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            recordIDs = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
                guard let uuid = UUID(uuidString: key) else { return nil }
                return (uuid, value)
            })
        }
    }

    private func saveRecordIDs() {
        let stringDict = Dictionary(uniqueKeysWithValues: recordIDs.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(stringDict) {
            UserDefaults.standard.set(data, forKey: recordIDsKey)
        }
    }

    private func loadDeletedEntryIDs() {
        if let data = UserDefaults.standard.data(forKey: deletedEntriesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            deletedEntryIDs = Set(decoded.compactMap { UUID(uuidString: $0) })
        }
    }

    private func saveDeletedEntryIDs() {
        let strings = deletedEntryIDs.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(strings) {
            UserDefaults.standard.set(data, forKey: deletedEntriesKey)
        }
    }
}
