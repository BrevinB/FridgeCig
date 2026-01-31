import Foundation
import CloudKit

@MainActor
class CloudKitManager: ObservableObject {
    static let containerID = "iCloud.co.brevinb.fridgecig"

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase

    @Published var isAvailable = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    init() {
        container = CKContainer(identifier: Self.containerID)
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            isAvailable = (status == .available)
        } catch {
            accountStatus = .couldNotDetermine
            isAvailable = false
        }
    }

    // MARK: - Private Database (User's own data)

    func saveToPrivate(_ record: CKRecord) async throws {
        let (saveResults, _) = try await privateDatabase.modifyRecords(
            saving: [record],
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, result) in saveResults {
            if case .failure(let error) = result {
                throw error
            }
        }
    }

    func fetchFromPrivate(recordType: String, predicate: NSPredicate = NSPredicate(value: true)) async throws -> [CKRecord] {
        // Use a query with TRUEPREDICATE which doesn't require indexed fields
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        // Sort by creation date to avoid needing queryable indexes
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await privateDatabase.records(matching: query, resultsLimit: 500)
            return results.compactMap { try? $0.1.get() }
        } catch let error as CKError where error.code == .unknownItem {
            // Schema doesn't exist yet
            return []
        } catch let error as CKError where error.code == .invalidArguments {
            // Query not supported - try fetching without query using record zone changes
            return try await fetchAllFromPrivateZone(recordType: recordType)
        }
    }

    /// Fetch all records of a type from the default zone using zone changes
    private func fetchAllFromPrivateZone(recordType: String) async throws -> [CKRecord] {
        let zoneID = CKRecordZone.default().zoneID

        // Fetch all record IDs first, then fetch the records
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))

        do {
            // Try a simpler query approach
            var allRecords: [CKRecord] = []
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID, resultsLimit: 500)
            allRecords = results.compactMap { try? $0.1.get() }
            return allRecords
        } catch {
            // If all else fails, return empty (schema may not exist)
            print("Failed to fetch from private zone: \(error)")
            return []
        }
    }

    func deleteFromPrivate(recordID: CKRecord.ID) async throws {
        try await privateDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Public Database (Leaderboard data)

    func saveToPublic(_ record: CKRecord) async throws {
        // Use modifyRecords with allKeys policy to handle both creates and updates
        let (saveResults, _) = try await publicDatabase.modifyRecords(
            saving: [record],
            deleting: [],
            savePolicy: .allKeys,  // Overwrites server record completely
            atomically: false
        )

        // Check if save succeeded
        for (_, result) in saveResults {
            if case .failure(let error) = result {
                throw error
            }
        }
    }

    func saveToPublicAndReturn(_ record: CKRecord) async throws -> CKRecord {
        let (saveResults, _) = try await publicDatabase.modifyRecords(
            saving: [record],
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (recordID, result) in saveResults {
            switch result {
            case .success(let savedRecord):
                return savedRecord
            case .failure(let error):
                throw error
            }
        }

        throw CKError(.unknownItem)
    }

    func fetchFromPublic(recordID: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await publicDatabase.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func fetchFromPublic(recordType: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil, limit: Int = 100) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        if let sortDescriptors = sortDescriptors {
            query.sortDescriptors = sortDescriptors
        }
        do {
            let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: limit)
            return results.compactMap { try? $0.1.get() }
        } catch let error as CKError where error.code == .unknownItem {
            // Schema doesn't exist yet
            return []
        }
    }

    func deleteFromPublic(recordID: CKRecord.ID) async throws {
        try await publicDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - User Profile Operations

    func fetchUserProfile(byFriendCode code: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "friendCode == %@", code.uppercased())
        do {
            let results = try await fetchFromPublic(recordType: "UserProfile", predicate: predicate, limit: 1)
            return results.first
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func fetchUserProfile(byUserID userID: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "userID == %@", userID)
        print("[CloudKit] fetchUserProfile byUserID: \(userID)")
        do {
            let results = try await fetchFromPublic(recordType: "UserProfile", predicate: predicate, limit: 1)
            print("[CloudKit] fetchUserProfile returned \(results.count) records")
            return results.first
        } catch let error as CKError where error.code == .unknownItem {
            print("[CloudKit] fetchUserProfile: schema doesn't exist")
            return nil
        } catch {
            print("[CloudKit] fetchUserProfile ERROR: \(error)")
            throw error
        }
    }

    func searchUserProfiles(byUsername query: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "username BEGINSWITH %@", query.lowercased())
        do {
            return try await fetchFromPublic(recordType: "UserProfile", predicate: predicate, limit: 20)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
    }

    func fetchLeaderboard(category: String, friendsOnly: Bool, friendIDs: [String]) async throws -> [CKRecord] {
        // If friendsOnly with no friends, return empty (avoid IN query with empty array)
        if friendsOnly && friendIDs.isEmpty {
            return []
        }

        let predicate: NSPredicate
        if friendsOnly {
            predicate = NSPredicate(format: "userID IN %@", friendIDs)
        } else {
            predicate = NSPredicate(format: "isPublic == YES")
        }

        let sortDescriptor = NSSortDescriptor(key: category, ascending: false)

        do {
            return try await fetchFromPublic(
                recordType: "UserProfile",
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                limit: 100
            )
        } catch let error as CKError where error.code == .unknownItem {
            // Schema doesn't exist yet - return empty until someone creates a profile
            return []
        } 
    }

    // MARK: - Friend Connection Operations

    func fetchFriendConnections(forUserID userID: String) async throws -> [CKRecord] {
        // CloudKit doesn't support OR in predicates, so we need two separate queries
        print("[CloudKit] fetchFriendConnections for userID: \(userID)")

        var allRecords: [CKRecord] = []
        var seenRecordIDs = Set<String>()

        // Query 1: Where user is the requester
        let predicate1 = NSPredicate(format: "requesterID == %@ AND status == %@", userID, "accepted")
        print("[CloudKit] fetchFriendConnections query 1: \(predicate1)")
        do {
            let records1 = try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate1)
            print("[CloudKit] fetchFriendConnections query 1 returned \(records1.count) records")
            for record in records1 {
                if !seenRecordIDs.contains(record.recordID.recordName) {
                    seenRecordIDs.insert(record.recordID.recordName)
                    allRecords.append(record)
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            print("[CloudKit] fetchFriendConnections query 1: schema doesn't exist yet")
        } catch {
            print("[CloudKit] fetchFriendConnections query 1 ERROR: \(error)")
            // Continue to try the second query
        }

        // Query 2: Where user is the target
        let predicate2 = NSPredicate(format: "targetID == %@ AND status == %@", userID, "accepted")
        print("[CloudKit] fetchFriendConnections query 2: \(predicate2)")
        do {
            let records2 = try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate2)
            print("[CloudKit] fetchFriendConnections query 2 returned \(records2.count) records")
            for record in records2 {
                if !seenRecordIDs.contains(record.recordID.recordName) {
                    seenRecordIDs.insert(record.recordID.recordName)
                    allRecords.append(record)
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            print("[CloudKit] fetchFriendConnections query 2: schema doesn't exist yet")
        } catch {
            print("[CloudKit] fetchFriendConnections query 2 ERROR: \(error)")
        }

        print("[CloudKit] fetchFriendConnections total: \(allRecords.count) records")
        return allRecords
    }

    func fetchPendingRequests(forUserID userID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "targetID == %@ AND status == %@", userID, "pending")
        print("[CloudKit] fetchPendingRequests for targetID: \(userID)")
        print("[CloudKit] fetchPendingRequests predicate: \(predicate)")
        do {
            let records = try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate)
            print("[CloudKit] fetchPendingRequests returned \(records.count) records")
            for record in records {
                let requesterID = record["requesterID"] as? String ?? "nil"
                let targetID = record["targetID"] as? String ?? "nil"
                let status = record["status"] as? String ?? "nil"
                print("[CloudKit]   - Record: requesterID=\(requesterID), targetID=\(targetID), status=\(status)")
            }
            return records
        } catch let error as CKError where error.code == .unknownItem {
            print("[CloudKit] fetchPendingRequests: schema doesn't exist yet")
            return []
        } catch {
            print("[CloudKit] fetchPendingRequests ERROR: \(error)")
            throw error
        }
    }

    func fetchSentRequests(forUserID userID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "requesterID == %@ AND status == %@", userID, "pending")
        print("[CloudKit] fetchSentRequests for requesterID: \(userID)")
        do {
            let records = try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate)
            print("[CloudKit] fetchSentRequests returned \(records.count) records")
            return records
        } catch let error as CKError where error.code == .unknownItem {
            print("[CloudKit] fetchSentRequests: schema doesn't exist yet")
            return []
        } catch {
            print("[CloudKit] fetchSentRequests ERROR: \(error)")
            throw error
        }
    }

    // MARK: - Friend Code Generation

    static func generateFriendCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    // MARK: - CloudKit Subscriptions

    /// Create or update a CloudKit query subscription
    func createSubscription(
        recordType: String,
        predicate: NSPredicate,
        subscriptionID: String,
        notificationInfo: CKSubscription.NotificationInfo,
        options: CKQuerySubscription.Options
    ) async {
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: options
        )
        subscription.notificationInfo = notificationInfo

        do {
            try await publicDatabase.save(subscription)
            print("[CloudKit] Created subscription: \(subscriptionID)")
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription might already exist, try to update it
            do {
                // First delete existing, then recreate
                try await publicDatabase.deleteSubscription(withID: subscriptionID)
                try await publicDatabase.save(subscription)
                print("[CloudKit] Updated subscription: \(subscriptionID)")
            } catch {
                print("[CloudKit] Failed to update subscription \(subscriptionID): \(error)")
            }
        } catch {
            print("[CloudKit] Failed to create subscription \(subscriptionID): \(error)")
        }
    }

    /// Remove a CloudKit subscription
    func removeSubscription(subscriptionID: String) async {
        do {
            try await publicDatabase.deleteSubscription(withID: subscriptionID)
            print("[CloudKit] Removed subscription: \(subscriptionID)")
        } catch let error as CKError where error.code == .unknownItem {
            // Subscription doesn't exist, that's fine
            print("[CloudKit] Subscription \(subscriptionID) not found (already removed)")
        } catch {
            print("[CloudKit] Failed to remove subscription \(subscriptionID): \(error)")
        }
    }

    /// Fetch all active subscriptions
    func fetchAllSubscriptions() async -> [CKSubscription] {
        do {
            return try await publicDatabase.allSubscriptions()
        } catch {
            print("[CloudKit] Failed to fetch subscriptions: \(error)")
            return []
        }
    }
}
