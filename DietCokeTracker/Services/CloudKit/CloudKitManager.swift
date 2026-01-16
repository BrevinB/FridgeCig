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
        do {
            let results = try await fetchFromPublic(recordType: "UserProfile", predicate: predicate, limit: 1)
            return results.first
        } catch let error as CKError where error.code == .unknownItem {
            return nil
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
        let predicate = NSPredicate(format: "(requesterID == %@ OR targetID == %@) AND status == %@", userID, userID, "accepted")
        do {
            return try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
    }

    func fetchPendingRequests(forUserID userID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "targetID == %@ AND status == %@", userID, "pending")
        do {
            return try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
    }

    func fetchSentRequests(forUserID userID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "requesterID == %@ AND status == %@", userID, "pending")
        do {
            return try await fetchFromPublic(recordType: "FriendConnection", predicate: predicate)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
    }

    // MARK: - Friend Code Generation

    static func generateFriendCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}
