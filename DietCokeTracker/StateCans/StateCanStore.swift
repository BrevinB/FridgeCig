import Foundation
import SwiftUI
import CloudKit
import Combine
import os

/// Per-state sync record. Treating the (collected, photos) pair as a single
/// record keyed off `lastModified` lets last-writer-wins propagate uncollects
/// and photo removals — a union merge would silently resurrect them.
struct StateCanRecord: Codable, Equatable {
    var collectedAt: Date?
    var photos: [String]
    var lastModified: Date

    init(collectedAt: Date? = nil, photos: [String] = [], lastModified: Date = Date()) {
        self.collectedAt = collectedAt
        self.photos = photos
        self.lastModified = lastModified
    }

    var isCollected: Bool { collectedAt != nil }
    var isVerified: Bool { !photos.isEmpty }
    var isTombstone: Bool { collectedAt == nil && photos.isEmpty }
}

@MainActor
class StateCanStore: ObservableObject {
    /// Authoritative per-state records. A record with `collectedAt == nil` and
    /// no photos is a tombstone — kept locally so a later sync from another
    /// device doesn't resurrect deletions. Tombstones never appear in the
    /// public `isCollected` / `isVerified` queries.
    @Published private(set) var records: [String: StateCanRecord] = [:]
    @Published var recentlyCollected: StateCan?
    @Published var isSyncing = false

    /// Emits when a state can is newly collected.
    let stateCollected = PassthroughSubject<StateCan, Never>()

    private let recordsSaveKey = "StateCanRecords"
    // Legacy keys for one-shot migration on first load.
    private let legacyCollectedKey = "CollectedStateCans"
    private let legacyPhotosKey = "StateCanPhotos"

    private let recordType = "StateCanData"
    private let recordIDKey = "StateCanDataRecordID"

    var cloudKitManager: CloudKitManager?
    private var cloudRecordID: CKRecord.ID?

    init() {
        loadRecords()
        loadRecordID()
    }

    // MARK: - Queries

    var collectedCount: Int {
        records.values.reduce(0) { $0 + ($1.isCollected ? 1 : 0) }
    }

    var verifiedCount: Int {
        records.values.reduce(0) { $0 + ($1.isVerified ? 1 : 0) }
    }

    var totalCount: Int { StateCan.all.count }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(collectedCount) / Double(totalCount) * 100
    }

    func isCollected(_ code: String) -> Bool {
        records[code]?.isCollected ?? false
    }

    func isVerified(_ code: String) -> Bool {
        records[code]?.isVerified ?? false
    }

    func collectionDate(_ code: String) -> Date? {
        records[code]?.collectedAt
    }

    func photoFilenames(for code: String) -> [String] {
        records[code]?.photos ?? []
    }

    // MARK: - Mutations

    /// Mark a state can as collected. Pass a `photoFilename` (already saved to
    /// `PhotoStorage`) to attach a verifying photo. Verified status can be
    /// upgraded later — calling collect again with a photo on an already-
    /// collected state appends the photo.
    func collect(_ code: String, on date: Date = Date(), photoFilename: String? = nil) {
        guard StateCan.byCode[code] != nil else { return }

        var record = records[code] ?? StateCanRecord()
        let wasCollected = record.isCollected
        let hadFilename = photoFilename.map { record.photos.contains($0) } ?? true

        if !wasCollected {
            record.collectedAt = date
        }
        if let filename = photoFilename, !record.photos.contains(filename) {
            record.photos.append(filename)
        }

        guard !wasCollected || !hadFilename else { return }

        record.lastModified = Date()
        records[code] = record
        saveRecords()

        if !wasCollected, let can = StateCan.byCode[code] {
            recentlyCollected = can
            stateCollected.send(can)
        }
    }

    func uncollect(_ code: String) {
        guard var record = records[code], record.isCollected else { return }
        // Delete photo files associated with this state.
        for filename in record.photos {
            PhotoStorage.deletePhoto(filename: filename)
        }
        record.collectedAt = nil
        record.photos = []
        record.lastModified = Date()
        records[code] = record   // keep the tombstone so sync can propagate the delete
        saveRecords()
    }

    /// Remove a single photo from a state can. The state stays collected; it
    /// just loses verified status if this was its only photo.
    func removePhoto(_ filename: String, from code: String) {
        guard var record = records[code], record.photos.contains(filename) else { return }
        record.photos.removeAll { $0 == filename }
        record.lastModified = Date()
        records[code] = record
        PhotoStorage.deletePhoto(filename: filename)
        saveRecords()
    }

    func dismissRecentlyCollected() {
        recentlyCollected = nil
    }

    // MARK: - Persistence

    private func saveRecords() {
        // Snapshot value-type dict for off-main encoding.
        let snapshot = records
        let key = recordsSaveKey

        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(snapshot)
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                await MainActor.run {
                    AppLogger.store.error("Failed to save state can records: \(error.localizedDescription)")
                }
            }
        }
        Task { try? await syncToCloud() }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsSaveKey) {
            do {
                records = try JSONDecoder().decode([String: StateCanRecord].self, from: data)
                return
            } catch {
                AppLogger.store.error("Failed to load state can records: \(error.localizedDescription)")
            }
        }
        // First run after upgrade: migrate from the legacy split format.
        migrateLegacyIfNeeded()
    }

    private func migrateLegacyIfNeeded() {
        let defaults = UserDefaults.standard
        let now = Date()
        var migrated: [String: StateCanRecord] = [:]

        if let data = defaults.data(forKey: legacyCollectedKey),
           let collected = try? JSONDecoder().decode([String: Date].self, from: data) {
            for (code, date) in collected {
                migrated[code] = StateCanRecord(collectedAt: date, photos: [], lastModified: now)
            }
        }
        if let data = defaults.data(forKey: legacyPhotosKey),
           let photos = try? JSONDecoder().decode([String: [String]].self, from: data) {
            for (code, filenames) in photos {
                var rec = migrated[code] ?? StateCanRecord(collectedAt: now, photos: [], lastModified: now)
                rec.photos = filenames
                migrated[code] = rec
            }
        }

        guard !migrated.isEmpty else { return }
        records = migrated
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsSaveKey)
        }
        // Clear legacy keys so we never re-run the migration.
        defaults.removeObject(forKey: legacyCollectedKey)
        defaults.removeObject(forKey: legacyPhotosKey)
    }

    // MARK: - CloudKit Sync

    func performSync() async {
        guard let cloudKitManager = cloudKitManager, cloudKitManager.isAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let cloudRecords = try await fetchFromCloud()

            // Per-key last-writer-wins. This lets uncollects (collectedAt=nil)
            // and photo removals propagate correctly: whichever side has the
            // newer `lastModified` wins entirely, tombstones included.
            var merged = records
            for (code, cloudRec) in cloudRecords {
                if let localRec = merged[code] {
                    merged[code] = cloudRec.lastModified > localRec.lastModified ? cloudRec : localRec
                } else {
                    merged[code] = cloudRec
                }
            }

            if merged != records {
                records = merged
                if let data = try? JSONEncoder().encode(records) {
                    UserDefaults.standard.set(data, forKey: recordsSaveKey)
                }
            }

            try await syncToCloud()
        } catch {
            AppLogger.sync.error("State can sync failed: \(error.localizedDescription)")
        }
    }

    private func fetchFromCloud() async throws -> [String: StateCanRecord] {
        guard let cloudKitManager = cloudKitManager else { return [:] }

        let records = try await cloudKitManager.fetchFromPrivate(recordType: recordType)
        guard let record = records.first else { return [:] }

        cloudRecordID = record.recordID
        saveRecordID()

        // New format.
        if let jsonData = record["recordsJSON"] as? String,
           let data = jsonData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: StateCanRecord].self, from: data) {
            return decoded
        }

        // Legacy format from earlier shipped builds — collected dates +
        // photo arrays as separate JSON fields. Synthesize a record per state.
        var migrated: [String: StateCanRecord] = [:]
        let now = Date()
        if let jsonData = record["statesJSON"] as? String,
           let data = jsonData.data(using: .utf8),
           let states = try? JSONDecoder().decode([String: Date].self, from: data) {
            for (code, date) in states {
                migrated[code] = StateCanRecord(collectedAt: date, photos: [], lastModified: now)
            }
        }
        if let jsonData = record["photosJSON"] as? String,
           let data = jsonData.data(using: .utf8),
           let photos = try? JSONDecoder().decode([String: [String]].self, from: data) {
            for (code, filenames) in photos {
                var rec = migrated[code] ?? StateCanRecord(collectedAt: now, photos: [], lastModified: now)
                rec.photos = filenames
                migrated[code] = rec
            }
        }
        return migrated
    }

    private func syncToCloud() async throws {
        guard let cloudKitManager = cloudKitManager, cloudKitManager.isAvailable else { return }

        let recordsData = try JSONEncoder().encode(records)
        guard let recordsJSON = String(data: recordsData, encoding: .utf8) else { return }

        let record: CKRecord
        if let existingID = cloudRecordID {
            record = CKRecord(recordType: recordType, recordID: existingID)
        } else {
            record = CKRecord(recordType: recordType)
        }

        record["recordsJSON"] = recordsJSON
        // Clear legacy fields so old clients don't read stale data and
        // resurrect deletions via the legacy path.
        record["statesJSON"] = nil
        record["photosJSON"] = nil

        try await cloudKitManager.saveToPrivate(record)
        cloudRecordID = record.recordID
        saveRecordID()
    }

    private func loadRecordID() {
        if let recordName = UserDefaults.standard.string(forKey: recordIDKey) {
            cloudRecordID = CKRecord.ID(recordName: recordName)
        }
    }

    private func saveRecordID() {
        if let recordID = cloudRecordID {
            UserDefaults.standard.set(recordID.recordName, forKey: recordIDKey)
        }
    }

    // MARK: - Debug

    #if DEBUG
    func collectAll() {
        let now = Date()
        for can in StateCan.all {
            var rec = records[can.code] ?? StateCanRecord()
            rec.collectedAt = now
            rec.lastModified = now
            records[can.code] = rec
        }
        saveRecords()
    }

    func resetAll() {
        for record in records.values {
            for filename in record.photos {
                PhotoStorage.deletePhoto(filename: filename)
            }
        }
        // Replace with tombstones so the reset propagates over CloudKit.
        let now = Date()
        var tombstoned: [String: StateCanRecord] = [:]
        for code in records.keys {
            tombstoned[code] = StateCanRecord(collectedAt: nil, photos: [], lastModified: now)
        }
        records = tombstoned
        saveRecords()
    }
    #endif
}
