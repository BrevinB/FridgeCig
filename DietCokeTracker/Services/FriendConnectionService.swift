import Foundation
import CloudKit

@MainActor
class FriendConnectionService: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var pendingRequests: [FriendConnection] = []
    @Published var sentRequests: [FriendConnection] = []
    @Published var isLoading = false
    @Published var error: FriendError?

    enum FriendError: Error, LocalizedError {
        case notFound
        case alreadyFriends
        case alreadyRequested
        case cannotAddSelf
        case fetchFailed(Error)
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "User not found"
            case .alreadyFriends:
                return "You're already friends"
            case .alreadyRequested:
                return "Friend request already sent"
            case .cannotAddSelf:
                return "You can't add yourself"
            case .fetchFailed(let error):
                return "Failed to load: \(error.localizedDescription)"
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    private let cloudKitManager: CloudKitManager
    private var connectionRecordIDs: [UUID: CKRecord.ID] = [:]

    var friendIDs: Set<String> {
        Set(friends.map { $0.userIDString })
    }

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    // MARK: - Load Data

    func loadFriends(forUserID userID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch accepted connections
            let connectionRecords = try await cloudKitManager.fetchFriendConnections(forUserID: userID)
            var connections: [FriendConnection] = []

            for record in connectionRecords {
                if let connection = FriendConnection(from: record) {
                    connections.append(connection)
                    connectionRecordIDs[connection.id] = record.recordID
                }
            }

            // Get friend user IDs
            let friendUserIDs = connections.map { $0.otherUserID(currentUserID: userID) }

            // Fetch friend profiles
            var loadedFriends: [UserProfile] = []
            for friendID in friendUserIDs {
                if let record = try await cloudKitManager.fetchUserProfile(byUserID: friendID),
                   let profile = UserProfile(from: record) {
                    loadedFriends.append(profile)
                }
            }

            friends = loadedFriends.sorted { $0.displayName < $1.displayName }

            // Fetch pending requests (requests TO this user)
            let pendingRecords = try await cloudKitManager.fetchPendingRequests(forUserID: userID)
            pendingRequests = pendingRecords.compactMap { record in
                if let connection = FriendConnection(from: record) {
                    connectionRecordIDs[connection.id] = record.recordID
                    return connection
                }
                return nil
            }

            // Fetch sent requests (requests FROM this user)
            let sentRecords = try await cloudKitManager.fetchSentRequests(forUserID: userID)
            sentRequests = sentRecords.compactMap { record in
                if let connection = FriendConnection(from: record) {
                    connectionRecordIDs[connection.id] = record.recordID
                    return connection
                }
                return nil
            }

        } catch {
            self.error = .fetchFailed(error)
        }
    }

    // MARK: - Friend Code Lookup

    func lookupUserByFriendCode(_ code: String) async throws -> UserProfile? {
        guard let record = try await cloudKitManager.fetchUserProfile(byFriendCode: code) else {
            return nil
        }
        return UserProfile(from: record)
    }

    // MARK: - Username Search

    func searchByUsername(_ query: String) async throws -> [UserProfile] {
        let records = try await cloudKitManager.searchUserProfiles(byUsername: query)
        return records.compactMap { UserProfile(from: $0) }
    }

    // MARK: - Send Friend Request

    func sendFriendRequest(from currentUserID: String, to targetProfile: UserProfile) async throws {
        // Check if trying to add self
        guard targetProfile.userIDString != currentUserID else {
            throw FriendError.cannotAddSelf
        }

        // Check if already friends
        if friends.contains(where: { $0.userIDString == targetProfile.userIDString }) {
            throw FriendError.alreadyFriends
        }

        // Check if already sent a request
        if sentRequests.contains(where: { $0.targetID == targetProfile.userIDString }) {
            throw FriendError.alreadyRequested
        }

        // Check if they already sent us a request (auto-accept)
        if let pendingRequest = pendingRequests.first(where: { $0.requesterID == targetProfile.userIDString }) {
            try await acceptRequest(pendingRequest, currentUserID: currentUserID)
            return
        }

        // Create new friend request
        let connection = FriendConnection(
            requesterID: currentUserID,
            targetID: targetProfile.userIDString
        )

        let record = connection.toCKRecord()
        try await cloudKitManager.saveToPublic(record)
        connectionRecordIDs[connection.id] = record.recordID
        sentRequests.append(connection)
    }

    // MARK: - Accept Request

    func acceptRequest(_ connection: FriendConnection, currentUserID: String) async throws {
        var updated = connection
        updated.status = .accepted
        updated.acceptedAt = Date()

        guard let recordID = connectionRecordIDs[connection.id] else {
            throw FriendError.saveFailed(NSError(domain: "", code: -1))
        }

        let record = updated.toCKRecord(existingRecordID: recordID)
        try await cloudKitManager.saveToPublic(record)

        // Remove from pending and add friend
        pendingRequests.removeAll { $0.id == connection.id }

        // Fetch the requester's profile
        if let requesterRecord = try await cloudKitManager.fetchUserProfile(byUserID: connection.requesterID),
           let requesterProfile = UserProfile(from: requesterRecord) {
            friends.append(requesterProfile)
            friends.sort { $0.displayName < $1.displayName }
        }
    }

    // MARK: - Decline/Remove

    func declineRequest(_ connection: FriendConnection) async throws {
        guard let recordID = connectionRecordIDs[connection.id] else { return }

        try await cloudKitManager.deleteFromPublic(recordID: recordID)
        pendingRequests.removeAll { $0.id == connection.id }
        connectionRecordIDs.removeValue(forKey: connection.id)
    }

    func removeFriend(_ profile: UserProfile, currentUserID: String) async throws {
        // Find the connection
        guard let connection = findConnection(with: profile.userIDString, currentUserID: currentUserID),
              let recordID = connectionRecordIDs[connection.id] else {
            return
        }

        try await cloudKitManager.deleteFromPublic(recordID: recordID)
        friends.removeAll { $0.id == profile.id }
        connectionRecordIDs.removeValue(forKey: connection.id)
    }

    private func findConnection(with otherUserID: String, currentUserID: String) -> FriendConnection? {
        // This would need to be tracked - for now we'll reload
        return nil
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(category: LeaderboardCategory, scope: LeaderboardScope, currentUserID: String?) async throws -> [LeaderboardEntry] {
        let records: [CKRecord]

        switch scope {
        case .friends:
            var ids = Array(friendIDs)
            if let currentUserID = currentUserID {
                ids.append(currentUserID)
            }
            records = try await cloudKitManager.fetchLeaderboard(
                category: category.sortKey,
                friendsOnly: true,
                friendIDs: ids
            )
        case .global:
            records = try await cloudKitManager.fetchLeaderboard(
                category: category.sortKey,
                friendsOnly: false,
                friendIDs: []
            )
        }

        let profiles = records.compactMap { UserProfile(from: $0) }
        let sorted = profiles.sorted { category.value(from: $0) > category.value(from: $1) }

        return sorted.enumerated().map { index, profile in
            LeaderboardEntry(
                from: profile,
                rank: index + 1,
                category: category,
                currentUserID: currentUserID,
                friendIDs: friendIDs
            )
        }
    }
}
