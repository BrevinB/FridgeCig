import Foundation
import CloudKit
import Combine

@MainActor
class IdentityService: ObservableObject {
    @Published var currentIdentity: UserIdentity?
    @Published var currentProfile: UserProfile?
    @Published var state: IdentityState = .loading
    @Published var error: IdentityError?

    enum IdentityState: Equatable {
        case loading
        case noIdentity
        case ready
        case error
    }

    enum IdentityError: Error, LocalizedError {
        case cloudKitUnavailable
        case saveFailed(Error)
        case fetchFailed(Error)

        var errorDescription: String? {
            switch self {
            case .cloudKitUnavailable:
                return "iCloud is not available. Your data will be stored locally."
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            case .fetchFailed(let error):
                return "Failed to fetch: \(error.localizedDescription)"
            }
        }
    }

    private let cloudKitManager: CloudKitManager
    private let localIdentityKey = "LocalUserIdentity"
    private var profileRecordID: CKRecord.ID?
    private var identityRecordID: CKRecord.ID?

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    // MARK: - Initialization

    func initialize() async {
        state = .loading

        // Check for local cache first
        if let localIdentity = loadLocalIdentity() {
            currentIdentity = localIdentity
        }

        // Check iCloud status
        await cloudKitManager.checkAccountStatus()

        if cloudKitManager.isAvailable {
            // Try to fetch from private iCloud (with retry)
            var fetchedIdentity: (UserIdentity, CKRecord.ID)?
            var fetchAttempts = 0
            let maxAttempts = 2

            while fetchedIdentity == nil && fetchAttempts < maxAttempts {
                fetchedIdentity = try? await fetchIdentityFromCloud()
                if fetchedIdentity == nil && fetchAttempts < maxAttempts - 1 {
                    // Wait a bit before retry
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
                fetchAttempts += 1
            }

            if let (identity, recordID) = fetchedIdentity {
                currentIdentity = identity
                identityRecordID = recordID
                saveLocalIdentity(identity)

                // Fetch or create public profile
                await fetchOrCreateProfile()
                state = .ready
            } else if let localIdentity = currentIdentity {
                // Have local but not in cloud - sync up
                do {
                    try await saveIdentityToCloud(localIdentity)
                    await fetchOrCreateProfile()
                } catch {
                    // Failed to sync, but still use local
                    if currentProfile == nil {
                        currentProfile = UserProfile(from: localIdentity)
                    }
                }
                state = .ready
            } else {
                // No identity anywhere
                state = .noIdentity
            }
        } else {
            // No iCloud - use local only with local profile
            if let identity = currentIdentity {
                // Create local-only profile
                if currentProfile == nil {
                    currentProfile = UserProfile(from: identity)
                }
                state = .ready
            } else {
                state = .noIdentity
            }
        }
    }

    // MARK: - Create Identity

    func createIdentity(displayName: String) async throws {
        let friendCode = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased())
        let identity = UserIdentity(displayName: displayName, friendCode: friendCode)
        currentIdentity = identity
        saveLocalIdentity(identity)

        if cloudKitManager.isAvailable {
            try await saveIdentityToCloud(identity)
            await fetchOrCreateProfile()
        } else {
            // Create local-only profile
            currentProfile = UserProfile(from: identity)
        }

        state = .ready
    }

    // MARK: - Update Profile

    func updateDisplayName(_ name: String) async throws {
        guard var identity = currentIdentity else { return }
        identity.displayName = name
        currentIdentity = identity
        saveLocalIdentity(identity)

        if cloudKitManager.isAvailable {
            if let recordID = identityRecordID {
                let record = identity.toCKRecord(existingRecordID: recordID)
                try await cloudKitManager.saveToPrivate(record)
            }

            // Update public profile too
            if var profile = currentProfile {
                profile.displayName = name
                currentProfile = profile
                if let recordID = profileRecordID {
                    let record = profile.toCKRecord(existingRecordID: recordID)
                    try await cloudKitManager.saveToPublic(record)
                }
            }
        }
    }

    func updateUsername(_ username: String?) async throws {
        guard var identity = currentIdentity else { return }
        identity.username = username?.lowercased()
        currentIdentity = identity
        saveLocalIdentity(identity)

        if cloudKitManager.isAvailable {
            if let recordID = identityRecordID {
                let record = identity.toCKRecord(existingRecordID: recordID)
                try await cloudKitManager.saveToPrivate(record)
            }

            if var profile = currentProfile {
                profile.username = username?.lowercased()
                currentProfile = profile
                if let recordID = profileRecordID {
                    let record = profile.toCKRecord(existingRecordID: recordID)
                    try await cloudKitManager.saveToPublic(record)
                }
            }
        }
    }

    func setPublicVisibility(_ isPublic: Bool) async throws {
        guard var profile = currentProfile else { return }
        profile.isPublic = isPublic
        currentProfile = profile

        if cloudKitManager.isAvailable, let recordID = profileRecordID {
            let record = profile.toCKRecord(existingRecordID: recordID)
            try await cloudKitManager.saveToPublic(record)
        }
    }

    // MARK: - Stats Sync

    func syncStats(from drinkStore: DrinkStore) async throws {
        guard var profile = currentProfile else { return }

        profile.updateStats(
            streak: drinkStore.streakDays,
            weeklyDrinks: drinkStore.thisWeekCount,
            weeklyOunces: drinkStore.thisWeekOunces,
            monthlyDrinks: drinkStore.thisMonthCount,
            monthlyOunces: drinkStore.thisMonthOunces,
            allTimeDrinks: drinkStore.allTimeCount,
            allTimeOunces: drinkStore.allTimeOunces
        )

        currentProfile = profile

        if cloudKitManager.isAvailable, let recordID = profileRecordID {
            let record = profile.toCKRecord(existingRecordID: recordID)
            try await cloudKitManager.saveToPublic(record)
        }
    }

    // MARK: - Private Helpers

    private func fetchIdentityFromCloud() async throws -> (UserIdentity, CKRecord.ID)? {
        do {
            let records = try await cloudKitManager.fetchFromPrivate(recordType: UserIdentity.recordType)
            guard let record = records.first,
                  let identity = UserIdentity(from: record) else {
                return nil
            }
            return (identity, record.recordID)
        } catch {
            // If fetch fails (schema not set up, etc.), return nil
            print("Identity fetch failed: \(error)")
            return nil
        }
    }

    private func saveIdentityToCloud(_ identity: UserIdentity) async throws {
        let record = identity.toCKRecord()
        try await cloudKitManager.saveToPrivate(record)
        identityRecordID = record.recordID
    }

    private func fetchOrCreateProfile() async {
        guard let identity = currentIdentity else { return }

        do {
            if let record = try await cloudKitManager.fetchUserProfile(byUserID: identity.userIDString) {
                currentProfile = UserProfile(from: record)
                profileRecordID = record.recordID
            } else {
                // Create new public profile
                let profile = UserProfile(from: identity)
                let record = profile.toCKRecord()
                try await cloudKitManager.saveToPublic(record)
                currentProfile = profile
                profileRecordID = record.recordID
            }
        } catch {
            self.error = .fetchFailed(error)
        }
    }

    // MARK: - Local Storage

    private func loadLocalIdentity() -> UserIdentity? {
        guard let data = UserDefaults.standard.data(forKey: localIdentityKey) else {
            return nil
        }
        return try? JSONDecoder().decode(UserIdentity.self, from: data)
    }

    private func saveLocalIdentity(_ identity: UserIdentity) {
        if let data = try? JSONEncoder().encode(identity) {
            UserDefaults.standard.set(data, forKey: localIdentityKey)
        }
    }

    // MARK: - Reset

    func resetIdentity() async {
        UserDefaults.standard.removeObject(forKey: localIdentityKey)
        currentIdentity = nil
        currentProfile = nil
        profileRecordID = nil
        identityRecordID = nil
        state = .noIdentity
    }
}

