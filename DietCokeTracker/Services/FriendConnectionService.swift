import Foundation
import CloudKit
import os

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

    private let cloudProvider: any CloudProvider
    private var connectionRecordIDs: [UUID: String] = [:]
    /// Maps friend userID to the record ID of the connection (for removal)
    private var friendConnectionRecordIDs: [String: String] = [:]

    var friendIDs: Set<String> {
        Set(friends.map { $0.userIDString })
    }

    init(cloudProvider: any CloudProvider) {
        self.cloudProvider = cloudProvider
    }

    // MARK: - Load Data

    func loadFriends(forUserID userID: String) async {
        isLoading = true
        defer { isLoading = false }

        AppLogger.friends.debug("Loading friends for userID: \(userID)")

        do {
            // Fetch accepted connections
            let connectionRecords = try await cloudProvider.fetchFriendConnections(forUserID: userID)
            AppLogger.friends.debug("Fetched \(connectionRecords.count) accepted connections")
            var connections: [FriendConnection] = []

            // Clear previous mappings
            friendConnectionRecordIDs.removeAll()

            for record in connectionRecords {
                if let connection = FriendConnection(from: record) {
                    connections.append(connection)
                    connectionRecordIDs[connection.id] = record.recordID
                    // Store mapping from friend's userID to record ID for easy removal
                    let friendUserID = connection.otherUserID(currentUserID: userID)
                    friendConnectionRecordIDs[friendUserID] = record.recordID
                }
            }

            // Get friend user IDs
            let friendUserIDs = connections.map { $0.otherUserID(currentUserID: userID) }

            // Fetch friend profiles
            var loadedFriends: [UserProfile] = []
            for friendID in friendUserIDs {
                if let record = try await cloudProvider.fetchUserProfile(byUserID: friendID),
                   let profile = UserProfile(from: record) {
                    loadedFriends.append(profile)
                }
            }

            friends = loadedFriends.sorted { $0.displayName < $1.displayName }

            // Fetch pending requests (requests TO this user)
            let pendingRecords = try await cloudProvider.fetchPendingRequests(forUserID: userID)
            AppLogger.friends.debug("Fetched \(pendingRecords.count) pending requests (to this user)")
            pendingRequests = pendingRecords.compactMap { record in
                if let connection = FriendConnection(from: record) {
                    connectionRecordIDs[connection.id] = record.recordID
                    AppLogger.friends.debug("Pending request from: \(connection.requesterID) to: \(connection.targetID)")
                    return connection
                } else {
                    AppLogger.friends.error("Failed to parse FriendConnection record!")
                }
                return nil
            }

            // Fetch sent requests (requests FROM this user)
            let sentRecords = try await cloudProvider.fetchSentRequests(forUserID: userID)
            AppLogger.friends.debug("Fetched \(sentRecords.count) sent requests (from this user)")
            sentRequests = sentRecords.compactMap { record in
                if let connection = FriendConnection(from: record) {
                    connectionRecordIDs[connection.id] = record.recordID
                    return connection
                }
                return nil
            }

            AppLogger.friends.info("Load complete - Friends: \(self.friends.count), Pending: \(self.pendingRequests.count), Sent: \(self.sentRequests.count)")

        } catch {
            AppLogger.friends.error("Loading friends failed: \(error.localizedDescription)")
            self.error = .fetchFailed(error)
        }
    }

    // MARK: - Friend Code Lookup

    func lookupUserByFriendCode(_ code: String) async throws -> UserProfile? {
        AppLogger.friends.debug("Looking up user by friend code: \(code)")
        guard let record = try await cloudProvider.fetchUserProfile(byFriendCode: code) else {
            AppLogger.friends.debug("No user found for friend code: \(code)")
            return nil
        }
        if let profile = UserProfile(from: record) {
            AppLogger.friends.info("Found user: \(profile.displayName), userID: \(profile.userIDString), friendCode: \(profile.friendCode)")
            return profile
        }
        AppLogger.friends.error("Failed to parse profile from record")
        return nil
    }

    // MARK: - User ID Lookup

    func lookupUserByID(_ userID: String) async throws -> UserProfile? {
        AppLogger.friends.debug("Looking up user by ID: \(userID)")
        #if DEBUG
        // Check for fake profiles first during testing
        if let fakeProfile = lookupFakeRequester(userID: userID) {
            AppLogger.friends.debug("Found fake profile for: \(userID)")
            return fakeProfile
        }
        #endif

        guard let record = try await cloudProvider.fetchUserProfile(byUserID: userID) else {
            AppLogger.friends.debug("No profile found for userID: \(userID)")
            return nil
        }
        if let profile = UserProfile(from: record) {
            AppLogger.friends.info("Found profile: \(profile.displayName) for userID: \(userID)")
            return profile
        }
        AppLogger.friends.error("Failed to parse profile record for userID: \(userID)")
        return nil
    }

    // MARK: - Username Search

    func searchByUsername(_ query: String) async throws -> [UserProfile] {
        let records = try await cloudProvider.searchUserProfiles(byUsername: query)
        return records.compactMap { UserProfile(from: $0) }
    }

    // MARK: - Send Friend Request

    func sendFriendRequest(from currentUserID: String, to targetProfile: UserProfile) async throws {
        AppLogger.friends.debug("=== SENDING FRIEND REQUEST ===")
        AppLogger.friends.debug("From (requesterID): \(currentUserID)")
        AppLogger.friends.debug("To (targetID): \(targetProfile.userIDString)")
        AppLogger.friends.debug("Target displayName: \(targetProfile.displayName)")
        AppLogger.friends.debug("Target friendCode: \(targetProfile.friendCode)")

        // Check if trying to add self
        guard targetProfile.userIDString != currentUserID else {
            AppLogger.friends.error("Cannot add self")
            throw FriendError.cannotAddSelf
        }

        // Check if already friends
        if friends.contains(where: { $0.userIDString == targetProfile.userIDString }) {
            AppLogger.friends.error("Already friends")
            throw FriendError.alreadyFriends
        }

        // Check if already sent a request
        if sentRequests.contains(where: { $0.targetID == targetProfile.userIDString }) {
            AppLogger.friends.error("Already sent a request")
            throw FriendError.alreadyRequested
        }

        // Check if they already sent us a request (auto-accept)
        if let pendingRequest = pendingRequests.first(where: { $0.requesterID == targetProfile.userIDString }) {
            AppLogger.friends.info("They already sent us a request - auto-accepting")
            try await acceptRequest(pendingRequest, currentUserID: currentUserID)
            return
        }

        // Create new friend request
        let connection = FriendConnection(
            requesterID: currentUserID,
            targetID: targetProfile.userIDString
        )

        AppLogger.friends.debug("Saving FriendConnection to cloud...")
        let record = connection.toCloudRecord()
        let saved = try await cloudProvider.saveToPublic(record)
        AppLogger.friends.info("FriendConnection saved successfully! RecordID: \(saved.recordID)")
        connectionRecordIDs[connection.id] = saved.recordID
        sentRequests.append(connection)
        AppLogger.friends.info("=== FRIEND REQUEST SENT SUCCESSFULLY ===")
    }

    // MARK: - Accept Request

    func acceptRequest(_ connection: FriendConnection, currentUserID: String) async throws {
        AppLogger.friends.debug("acceptRequest for connection.id: \(connection.id)")

        var updated = connection
        updated.status = .accepted
        updated.acceptedAt = Date()

        guard let recordID = connectionRecordIDs[connection.id] else {
            AppLogger.friends.error("No recordID found for connection.id: \(connection.id)")
            throw FriendError.saveFailed(NSError(domain: "FriendService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Record ID not found"]))
        }
        AppLogger.friends.debug("Found recordID: \(recordID)")

        let record = updated.toCloudRecord(existingRecordID: recordID)
        try await cloudProvider.saveToPublic(record)

        // Remove from pending and add friend
        pendingRequests.removeAll { $0.id == connection.id }

        // Fetch the requester's profile
        if let requesterRecord = try await cloudProvider.fetchUserProfile(byUserID: connection.requesterID),
           let requesterProfile = UserProfile(from: requesterRecord) {
            friends.append(requesterProfile)
            friends.sort { $0.displayName < $1.displayName }
        }
    }

    // MARK: - Decline/Remove

    func declineRequest(_ connection: FriendConnection) async throws {
        AppLogger.friends.debug("declineRequest for connection.id: \(connection.id)")

        guard let recordID = connectionRecordIDs[connection.id] else {
            AppLogger.friends.error("No recordID found for connection.id: \(connection.id)")
            throw FriendError.saveFailed(NSError(domain: "FriendService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Record ID not found for decline"]))
        }
        AppLogger.friends.debug("Found recordID: \(recordID), deleting...")

        try await cloudProvider.deleteFromPublic(recordID: recordID)
        pendingRequests.removeAll { $0.id == connection.id }
        connectionRecordIDs.removeValue(forKey: connection.id)
        AppLogger.friends.info("Decline completed successfully")
    }

    func removeFriend(_ profile: UserProfile, currentUserID: String) async throws {
        AppLogger.friends.debug("Removing friend: \(profile.displayName) (userID: \(profile.userIDString))")

        // Find the connection record ID using the friend's userID
        guard let recordID = friendConnectionRecordIDs[profile.userIDString] else {
            AppLogger.friends.error("No connection record found for userID: \(profile.userIDString)")
            throw FriendError.notFound
        }

        AppLogger.friends.debug("Found connection recordID: \(recordID), deleting...")

        try await cloudProvider.deleteFromPublic(recordID: recordID)

        // Update local state
        friends.removeAll { $0.id == profile.id }
        friendConnectionRecordIDs.removeValue(forKey: profile.userIDString)

        AppLogger.friends.info("Friend removed successfully")
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(category: LeaderboardCategory, scope: LeaderboardScope, currentUserID: String?) async throws -> [LeaderboardEntry] {
        let records: [CloudRecord]

        switch scope {
        case .friends:
            var ids = Array(friendIDs)
            if let currentUserID = currentUserID {
                ids.append(currentUserID)
            }
            records = try await cloudProvider.fetchLeaderboard(
                category: category.sortKey,
                friendsOnly: true,
                friendIDs: ids
            )
        case .global:
            records = try await cloudProvider.fetchLeaderboard(
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

    // MARK: - Debug

    #if DEBUG
    @Published var isUsingFakeData = false

    /// Stores fake requester profiles for lookup during testing
    private var fakeRequesterProfiles: [String: UserProfile] = [:]

    func addFakeFriends() {
        let fakeFriends: [UserProfile] = [
            createFakeProfile(name: "DCFan", username: "dcfan99", streak: 45, weekly: 28, monthly: 112, allTime: 1847),
            createFakeProfile(name: "CokeZeroKing", username: "cokezeroking", streak: 180, weekly: 35, monthly: 140, allTime: 4521),
            createFakeProfile(name: "FountainFinder", username: "fountainfinder", streak: 12, weekly: 21, monthly: 84, allTime: 892),
            createFakeProfile(name: "SodaQueen", username: "sodaqueen", streak: 67, weekly: 42, monthly: 168, allTime: 2156),
            createFakeProfile(name: "BubbleMaster", username: "bubblemaster", streak: 7, weekly: 14, monthly: 56, allTime: 423),
        ]
        friends = fakeFriends
        isUsingFakeData = true
    }

    func clearFakeFriends() {
        friends = []
        isUsingFakeData = false
    }

    /// Simulates receiving friend requests from fake users
    func addFakePendingRequests(targetUserID: String) {
        let fakeRequesters: [(name: String, username: String)] = [
            ("CaffeineCraver", "caffeinecraver"),
            ("DietDrinker42", "dietdrinker42"),
            ("SipMaster", "sipmaster"),
        ]

        var newRequests: [FriendConnection] = []

        for requester in fakeRequesters {
            let profile = createFakeProfile(
                name: requester.name,
                username: requester.username,
                streak: Int.random(in: 5...100),
                weekly: Int.random(in: 10...50),
                monthly: Int.random(in: 40...200),
                allTime: Int.random(in: 500...3000)
            )

            // Store profile for lookup
            fakeRequesterProfiles[profile.userIDString] = profile

            // Create pending request
            let request = FriendConnection(
                requesterID: profile.userIDString,
                targetID: targetUserID,
                status: .pending,
                createdAt: Date().addingTimeInterval(-Double.random(in: 60...3600))
            )
            newRequests.append(request)
        }

        pendingRequests = newRequests
        isUsingFakeData = true
    }

    func clearFakePendingRequests() {
        pendingRequests = []
        fakeRequesterProfiles = [:]
    }

    /// Override lookup to return fake profiles during testing
    func lookupFakeRequester(userID: String) -> UserProfile? {
        return fakeRequesterProfiles[userID]
    }

    /// Returns fake leaderboard entries from local friends data + current user
    func getFakeLeaderboard(category: LeaderboardCategory, currentUserID: String?, currentUserProfile: UserProfile?) -> [LeaderboardEntry] {
        // Combine fake friends with current user
        var allProfiles = friends
        if let currentProfile = currentUserProfile {
            allProfiles.append(currentProfile)
        }

        let sorted = allProfiles.sorted { category.value(from: $0) > category.value(from: $1) }
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

    private func createFakeProfile(name: String, username: String, streak: Int, weekly: Int, monthly: Int, allTime: Int) -> UserProfile {
        let identity = UserIdentity(
            id: UUID(),
            displayName: name,
            friendCode: String(format: "%06d", Int.random(in: 100000...999999)),
            username: username,
            createdAt: Date().addingTimeInterval(-Double.random(in: 86400...31536000))
        )
        var profile = UserProfile(from: identity)
        profile.currentStreak = streak
        profile.weeklyDrinks = weekly
        profile.weeklyOunces = Double(weekly) * 12.0
        profile.monthlyDrinks = monthly
        profile.monthlyOunces = Double(monthly) * 12.0
        profile.allTimeDrinks = allTime
        profile.allTimeOunces = Double(allTime) * 12.0
        return profile
    }
    #endif

    // MARK: - Data Management

    /// Clear all local friend data (used for account deletion)
    func clearAllData() {
        friends = []
        pendingRequests = []
        #if DEBUG
        fakeRequesterProfiles = [:]
        isUsingFakeData = false
        #endif
    }
}
