import Foundation

// MARK: - CloudProvider Protocol

/// Abstraction layer for cloud database operations.
///
/// This protocol decouples the app's data services from any specific cloud backend.
/// By coding against `CloudProvider` instead of `CloudKitManager` directly, the app
/// can support multiple backends:
///
/// - **CloudKit** (iOS/macOS) — Apple's native cloud, current production backend
/// - **Firebase Firestore** (cross-platform) — enables Android and web support
/// - **Custom REST API** — full control over the backend
///
/// ## Architecture for Cross-Platform Support
///
/// ```
/// ┌─────────────┐    ┌──────────────┐    ┌──────────────┐
/// │   iOS App    │    │  Android App │    │   Web App    │
/// │  (SwiftUI)   │    │  (Kotlin)    │    │  (React)     │
/// └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
///        │                   │                   │
///        ▼                   ▼                   ▼
/// ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
/// │ CloudKit     │    │  Firebase    │    │  Firebase    │
/// │ Provider     │    │  Provider    │    │    SDK       │
/// └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
///        │                   │                   │
///        ▼                   ▼                   ▼
/// ┌──────────────┐    ┌──────────────────────────────────┐
/// │   iCloud     │    │        Firebase / Shared API      │
/// │  (private    │    │  (profiles, friends, leaderboard, │
/// │   data)      │    │   activity feed — cross-platform) │
/// └──────────────┘    └──────────────────────────────────┘
/// ```
///
/// **Private data** (drink entries) can stay on each platform's native storage.
/// **Social data** (profiles, friends, leaderboard, activity feed) should use a
/// shared backend so iOS and Android users can interact with each other.
@MainActor
protocol CloudProvider: AnyObject {

    /// Whether the cloud backend is currently available and authenticated
    var isAvailable: Bool { get }

    /// Check the user's account/authentication status
    func checkAccountStatus() async

    // MARK: - Private Database (User's Own Data)

    /// Save a record to the user's private data store.
    /// Returns the saved record with server-assigned ID and metadata.
    @discardableResult
    func saveToPrivate(_ record: CloudRecord) async throws -> CloudRecord

    /// Fetch all records of a given type from the user's private store.
    func fetchFromPrivate(recordType: String) async throws -> [CloudRecord]

    /// Delete a record from the user's private store by its record ID.
    func deleteFromPrivate(recordID: String) async throws

    // MARK: - Public Database (Shared/Social Data)

    /// Save a record to the shared/public data store.
    /// Returns the saved record with server-assigned ID and metadata.
    @discardableResult
    func saveToPublic(_ record: CloudRecord) async throws -> CloudRecord

    /// Fetch records from the public store matching filters.
    func fetchFromPublic(
        recordType: String,
        filters: [QueryFilter],
        sorts: [QuerySort],
        limit: Int
    ) async throws -> [CloudRecord]

    /// Fetch a single record from the public store by ID.
    func fetchFromPublic(recordID: String, recordType: String) async throws -> CloudRecord?

    /// Delete a record from the public store by its record ID.
    func deleteFromPublic(recordID: String) async throws

    // MARK: - Asset/File Operations

    /// Upload binary data (e.g., a photo) and return a reference ID.
    func uploadAsset(_ data: Data, recordType: String, fieldName: String) async throws -> String

    /// Download binary data by its reference ID.
    func downloadAsset(recordID: String, fieldName: String) async throws -> Data?

    // MARK: - Subscriptions / Real-time Updates

    /// Subscribe to changes on a record type matching filters.
    /// Returns true if subscription was created successfully.
    @discardableResult
    func subscribe(
        to recordType: String,
        filters: [QueryFilter],
        subscriptionID: String
    ) async -> Bool

    /// Remove a subscription.
    func unsubscribe(subscriptionID: String) async
}

// MARK: - Convenience Query Methods

/// Default implementations for common query patterns used across the app.
/// These build on the core `fetchFromPublic` method.
extension CloudProvider {

    func fetchUserProfile(byFriendCode code: String) async throws -> CloudRecord? {
        let results = try await fetchFromPublic(
            recordType: "UserProfile",
            filters: [.equals(field: "friendCode", value: .string(code.uppercased()))],
            sorts: [],
            limit: 1
        )
        return results.first
    }

    func fetchUserProfile(byUserID userID: String) async throws -> CloudRecord? {
        let results = try await fetchFromPublic(
            recordType: "UserProfile",
            filters: [.equals(field: "userID", value: .string(userID))],
            sorts: [],
            limit: 1
        )
        return results.first
    }

    func searchUserProfiles(byUsername query: String) async throws -> [CloudRecord] {
        try await fetchFromPublic(
            recordType: "UserProfile",
            filters: [.beginsWith(field: "username", prefix: query.lowercased())],
            sorts: [],
            limit: 20
        )
    }

    func fetchLeaderboard(category: String, friendsOnly: Bool, friendIDs: [String]) async throws -> [CloudRecord] {
        if friendsOnly && friendIDs.isEmpty { return [] }

        let filters: [QueryFilter]
        if friendsOnly {
            filters = [.containedIn(field: "userID", values: friendIDs)]
        } else {
            filters = [.equals(field: "isPublic", value: .bool(true))]
        }

        return try await fetchFromPublic(
            recordType: "UserProfile",
            filters: filters,
            sorts: [QuerySort(category, ascending: false)],
            limit: 100
        )
    }

    func fetchFriendConnections(forUserID userID: String) async throws -> [CloudRecord] {
        // Need two queries since most backends don't support OR
        let asRequester = try await fetchFromPublic(
            recordType: "FriendConnection",
            filters: [
                .equals(field: "requesterID", value: .string(userID)),
                .equals(field: "status", value: .string("accepted"))
            ],
            sorts: [],
            limit: 100
        )

        let asTarget = try await fetchFromPublic(
            recordType: "FriendConnection",
            filters: [
                .equals(field: "targetID", value: .string(userID)),
                .equals(field: "status", value: .string("accepted"))
            ],
            sorts: [],
            limit: 100
        )

        // Deduplicate by record ID
        var seen = Set<String>()
        var all: [CloudRecord] = []
        for record in asRequester + asTarget {
            if seen.insert(record.recordID).inserted {
                all.append(record)
            }
        }
        return all
    }

    func fetchPendingRequests(forUserID userID: String) async throws -> [CloudRecord] {
        try await fetchFromPublic(
            recordType: "FriendConnection",
            filters: [
                .equals(field: "targetID", value: .string(userID)),
                .equals(field: "status", value: .string("pending"))
            ],
            sorts: [],
            limit: 100
        )
    }

    func fetchSentRequests(forUserID userID: String) async throws -> [CloudRecord] {
        try await fetchFromPublic(
            recordType: "FriendConnection",
            filters: [
                .equals(field: "requesterID", value: .string(userID)),
                .equals(field: "status", value: .string("pending"))
            ],
            sorts: [],
            limit: 100
        )
    }

    func fetchActivities(forUserIDs userIDs: [String], limit: Int) async throws -> [CloudRecord] {
        guard !userIDs.isEmpty else { return [] }
        return try await fetchFromPublic(
            recordType: "ActivityItem",
            filters: [.containedIn(field: "userID", values: userIDs)],
            sorts: [QuerySort("timestamp", ascending: false)],
            limit: limit
        )
    }
}
