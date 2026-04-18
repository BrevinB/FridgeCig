import Foundation
import SwiftUI
import UIKit
import CloudKit
import Combine
import os

@MainActor
class ActivityFeedService: ObservableObject {
    @Published var activities: [ActivityItem] = []
    @Published private(set) var isLoading = false
    @Published var sharingPreferences: UserSharingPreferences

    /// Emits when a global photo activity is posted (for GlobalFeedService to pick up)
    let globalPhotoPosted = PassthroughSubject<ActivityItem, Never>()

    /// Emits when cheers are updated (activityID, newCount, newUserIDs)
    let cheersUpdated = PassthroughSubject<(UUID, Int, [String]), Never>()

    private let cloudKitManager: CloudKitManager
    private let preferencesKey = "UserSharingPreferences"
    private var friendIDs: [String] = []
    private var currentUserID: String?
    private var currentProfilePhotoID: String?
    private var currentProfileEmoji: String?
    private var blockedUserIDs: Set<String> = []
    private var photoCache: [String: UIImage] = [:]

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
        self.sharingPreferences = Self.loadPreferences()
    }

    // MARK: - Configure

    private var avatarMap: [String: (photoID: String?, emoji: String?)] = [:]

    func configure(currentUserID: String, friendIDs: [String], profilePhotoID: String? = nil, profileEmoji: String? = nil) {
        self.currentUserID = currentUserID
        self.friendIDs = friendIDs
        self.currentProfilePhotoID = profilePhotoID
        self.currentProfileEmoji = profileEmoji
        avatarMap[currentUserID] = (profilePhotoID, profileEmoji)
    }

    func updateAvatarMap(from profiles: [UserProfile]) {
        for profile in profiles {
            avatarMap[profile.userIDString] = (profile.profilePhotoID, profile.profileEmoji)
        }
    }

    func configure(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
        // Remove any existing activities from blocked users
        activities.removeAll { blockedUserIDs.contains($0.userID) }
    }

    // MARK: - Fetch Activities

    private var isCurrentlyFetching = false
    private var lastFetchDate: Date?
    private var lastFetchKey: String?
    private let freshnessWindow: TimeInterval = 30

    private func makeFetchKey() -> String {
        let sortedFriends = friendIDs.sorted().joined(separator: ",")
        return "\(currentUserID ?? "")|\(sortedFriends)"
    }

    func fetchActivities(force: Bool = false) async {
        AppLogger.activity.debug("fetchActivities called (force: \(force))")
        AppLogger.activity.debug("currentUserID: \(self.currentUserID ?? "nil")")
        AppLogger.activity.debug("friendIDs: \(self.friendIDs)")

        #if DEBUG
        // Don't overwrite fake data
        if isUsingFakeData {
            AppLogger.activity.debug("Using fake data, skipping fetch")
            return
        }
        #endif

        // Need at least current user to fetch
        guard currentUserID != nil || !friendIDs.isEmpty else {
            AppLogger.activity.debug("No userID or friends, skipping fetch")
            // Don't clear activities - keep any locally posted ones
            return
        }

        // Freshness gate: skip if same config was fetched recently
        let fetchKey = makeFetchKey()
        if !force, let lastKey = lastFetchKey, lastKey == fetchKey,
           let lastDate = lastFetchDate,
           Date().timeIntervalSince(lastDate) < freshnessWindow {
            AppLogger.activity.debug("Skipping fetch - data is fresh (\(Int(Date().timeIntervalSince(lastDate)))s old)")
            return
        }

        // Prevent redundant concurrent fetches
        guard !isCurrentlyFetching else { return }
        isCurrentlyFetching = true
        isLoading = true
        defer {
            isLoading = false
            isCurrentlyFetching = false
        }

        do {
            let records = try await fetchActivityRecords()
            AppLogger.activity.info("Fetched \(records.count) records from CloudKit")

            let fetchedActivities = records.compactMap { ActivityItem(from: $0) }
                .filter { !blockedUserIDs.contains($0.userID) }
                .filter { $0.visibility != .onlyMe || $0.userID == currentUserID }
            AppLogger.activity.debug("Parsed \(fetchedActivities.count) activities")

            // Merge fetched activities with local ones (keep local activities that aren't in CloudKit yet)
            let fetchedIDs = Set(fetchedActivities.map { $0.id })
            let localOnlyActivities = activities.filter { !fetchedIDs.contains($0.id) }
            AppLogger.activity.debug("Local-only activities: \(localOnlyActivities.count)")

            // Refresh stale avatars from known profiles
            let refreshed = (fetchedActivities + localOnlyActivities).map { item -> ActivityItem in
                guard let avatar = avatarMap[item.userID] else { return item }
                var updated = item
                if updated.profilePhotoID != avatar.photoID { updated.profilePhotoID = avatar.photoID }
                if updated.profileEmoji != avatar.emoji { updated.profileEmoji = avatar.emoji }
                return updated
            }

            // Combine and sort by timestamp
            activities = refreshed
                .sorted { $0.timestamp > $1.timestamp }
            AppLogger.activity.info("Total activities after merge: \(self.activities.count)")

            lastFetchKey = fetchKey
            lastFetchDate = Date()
        } catch {
            AppLogger.activity.error("Failed to fetch activities: \(error.localizedDescription)")
            // Keep existing activities on error
        }
    }

    private func fetchActivityRecords() async throws -> [CKRecord] {
        // Build list of user IDs to fetch (current user + friends)
        var allUserIDs = friendIDs
        if let currentID = currentUserID {
            allUserIDs.append(currentID)
        }

        guard !allUserIDs.isEmpty else {
            AppLogger.activity.debug("No user IDs to fetch activities for")
            return []
        }

        AppLogger.activity.debug("Fetching activities for userIDs: \(allUserIDs)")
        let predicate = NSPredicate(format: "userID IN %@", allUserIDs)
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

        do {
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                limit: Constants.Sync.activityFeedLimit
            )
            AppLogger.activity.debug("CloudKit returned \(records.count) ActivityItem records")
            return records
        } catch {
            AppLogger.activity.error("CloudKit fetch error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Post Activities

    func postBadgeActivity(badge: Badge, userID: String, displayName: String, isPremium: Bool = false) async {
        AppLogger.activity.debug("postBadgeActivity called for badge: \(badge.title)")
        guard sharingPreferences.shareBadges else {
            AppLogger.activity.debug("Badge sharing disabled, skipping")
            return
        }

        let activity = ActivityItem(
            userID: userID,
            displayName: displayName,
            type: .badgeUnlock,
            payload: .forBadge(badge),
            isPremium: isPremium,
            profilePhotoID: currentProfilePhotoID,
            profileEmoji: currentProfileEmoji
        )

        await postActivity(activity)
    }

    func postStreakActivity(days: Int, userID: String, displayName: String, isPremium: Bool = false) async {
        AppLogger.activity.debug("postStreakActivity called for \(days) days")
        guard sharingPreferences.shareStreakMilestones else {
            AppLogger.activity.debug("Streak sharing disabled, skipping")
            return
        }

        // Only post for milestone streaks
        let milestones = [7, 30, 100, 365]
        guard milestones.contains(days) else {
            AppLogger.activity.debug("\(days) is not a milestone, skipping")
            return
        }

        AppLogger.activity.info("Posting streak milestone: \(days) days")
        let activity = ActivityItem(
            userID: userID,
            displayName: displayName,
            type: .streakMilestone,
            payload: .forStreak(days),
            isPremium: isPremium,
            profilePhotoID: currentProfilePhotoID,
            profileEmoji: currentProfileEmoji
        )

        await postActivity(activity)
    }

    func postDrinkActivity(type: DrinkType, note: String?, photo: UIImage?, userID: String, displayName: String, entryID: String, isPremium: Bool = false, rating: DrinkRating? = nil, ounces: Double? = nil, specialEdition: SpecialEdition? = nil, brand: BeverageBrand? = nil, visibility: PostVisibility = .friends) async {
        AppLogger.activity.debug("postDrinkActivity called for type: \(type.displayName) visibility: \(visibility.rawValue)")

        let hasPhoto = photo != nil
        var photoURL: String? = nil
        var isGlobalPhoto = false

        // Upload photo if visibility allows sharing
        if let photo = photo {
            photoURL = await uploadPhoto(photo)

            // Mark as global if user chose public visibility and photo is safe
            if visibility == .public, photoURL != nil {
                let verificationService = ImageVerificationService()
                let safetyResult = await verificationService.classifyForSafety(photo)
                isGlobalPhoto = safetyResult.isSafe
                if !safetyResult.isSafe {
                    AppLogger.activity.info("Photo blocked from global feed: \(safetyResult.flaggedCategories.joined(separator: ", "))")
                }
            }
        }

        let activity = ActivityItem(
            userID: userID,
            displayName: displayName,
            type: .drinkLog,
            payload: .forDrink(type: type, note: note, hasPhoto: hasPhoto, photoURL: photoURL, entryID: entryID, rating: rating, ounces: ounces, specialEdition: specialEdition, brand: brand),
            isPremium: isPremium,
            isGlobalPhoto: isGlobalPhoto,
            visibility: visibility,
            profilePhotoID: currentProfilePhotoID,
            profileEmoji: currentProfileEmoji
        )

        await postActivity(activity)
    }

    /// Delete a drink activity when the drink entry is deleted
    func deleteDrinkActivity(entryID: String, userID: String) async {
        AppLogger.activity.debug("deleteDrinkActivity called for entryID: \(entryID)")

        // Remove from local list
        activities.removeAll { activity in
            activity.type == .drinkLog && activity.payload.drinkEntryID == entryID
        }

        // Delete from CloudKit using the top-level entryID field for efficient lookup
        do {
            let predicate = NSPredicate(format: "entryID == %@ AND userID == %@", entryID, userID)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                limit: 1
            )

            if let record = records.first {
                try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
                AppLogger.activity.info("Deleted activity from CloudKit for entryID: \(entryID)")
            } else {
                // Fallback: query by userID and check payload JSON (for older records without entryID field)
                let fallbackPredicate = NSPredicate(format: "userID == %@ AND type == %@", userID, ActivityType.drinkLog.rawValue)
                let fallbackRecords = try await cloudKitManager.fetchFromPublic(
                    recordType: ActivityItem.recordType,
                    predicate: fallbackPredicate,
                    limit: 100
                )

                for record in fallbackRecords {
                    if let payloadJSON = record["payloadJSON"] as? String,
                       let payloadData = payloadJSON.data(using: .utf8),
                       let payload = try? JSONDecoder().decode(ActivityPayload.self, from: payloadData),
                       payload.drinkEntryID == entryID {
                        try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
                        AppLogger.activity.info("Deleted activity via fallback for entryID: \(entryID)")
                        break
                    }
                }
            }
        } catch {
            AppLogger.activity.error("Failed to delete activity from CloudKit: \(error.localizedDescription)")
        }
    }

    private func uploadPhoto(_ image: UIImage) async -> String? {
        // Compress image for upload
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            AppLogger.activity.error("Failed to compress image")
            return nil
        }

        // Create temporary file for CKAsset
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        do {
            try imageData.write(to: tempURL)

            // Create CKAsset and upload
            let asset = CKAsset(fileURL: tempURL)
            let record = CKRecord(recordType: "ActivityPhoto")
            record["photo"] = asset
            record["uploadedAt"] = Date()

            let savedRecord = try await cloudKitManager.saveToPublicAndReturn(record)

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

            // Return the record ID as the photo reference
            return savedRecord.recordID.recordName
        } catch {
            AppLogger.activity.error("Failed to upload photo: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    func fetchPhoto(recordName: String) async -> UIImage? {
        if let cached = photoCache[recordName] {
            return cached
        }

        do {
            let recordID = CKRecord.ID(recordName: recordName)
            guard let record = try await cloudKitManager.fetchFromPublic(recordID: recordID),
                  let asset = record["photo"] as? CKAsset,
                  let fileURL = asset.fileURL,
                  let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else {
                return nil
            }
            photoCache[recordName] = image
            return image
        } catch {
            AppLogger.activity.error("Failed to fetch photo: \(error.localizedDescription)")
            return nil
        }
    }

    private func postActivity(_ activity: ActivityItem) async {
        AppLogger.activity.debug("Posting activity: \(activity.type.rawValue) by \(activity.displayName)")

        // Add to local list immediately
        activities.insert(activity, at: 0)

        // Try to save to CloudKit
        do {
            let record = activity.toCKRecord()
            try await cloudKitManager.saveToPublic(record)
            AppLogger.activity.info("Activity posted to CloudKit successfully")
        } catch {
            AppLogger.activity.error("Failed to post activity to CloudKit: \(error.localizedDescription)")
        }

        // Notify global feed if this is a global photo
        if activity.isGlobalPhoto {
            globalPhotoPosted.send(activity)
        }
    }

    // MARK: - Cheers (Reactions)

    func toggleCheers(for activity: ActivityItem) async {
        guard let currentID = currentUserID else { return }

        // Build updated cheers data from the source of truth
        var cheersUserIDs = activity.cheersUserIDs
        var cheersCount = activity.cheersCount

        if cheersUserIDs.contains(currentID) {
            cheersUserIDs.removeAll { $0 == currentID }
            cheersCount = max(0, cheersCount - 1)
        } else {
            cheersUserIDs.append(currentID)
            cheersCount += 1
        }

        // Update in activities list (friends feed) if present
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index].cheersUserIDs = cheersUserIDs
            activities[index].cheersCount = cheersCount
        }

        // Notify so GlobalFeedService can update too
        cheersUpdated.send((activity.id, cheersCount, cheersUserIDs))

        // Sync to cloud with conflict resolution
        let userToToggle = currentID
        do {
            let predicate = NSPredicate(format: "activityID == %@", activity.id.uuidString)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                limit: 1
            )

            if let existingRecord = records.first {
                existingRecord["cheersCount"] = cheersCount
                existingRecord["cheersUserIDs"] = cheersUserIDs

                try await cloudKitManager.saveToPublicWithConflictResolution(existingRecord) { serverRecord, localRecord in
                    // Merge: re-apply the toggle on top of the server's current state
                    var serverUserIDs = serverRecord["cheersUserIDs"] as? [String] ?? []
                    if serverUserIDs.contains(userToToggle) {
                        serverUserIDs.removeAll { $0 == userToToggle }
                    } else {
                        serverUserIDs.append(userToToggle)
                    }
                    serverRecord["cheersUserIDs"] = serverUserIDs
                    serverRecord["cheersCount"] = serverUserIDs.count
                }
            }
        } catch {
            AppLogger.activity.error("Failed to update cheers: \(error.localizedDescription)")
        }
    }

    func hasUserCheered(_ activity: ActivityItem) -> Bool {
        guard let currentID = currentUserID else { return false }
        // Check the live list first (friends feed), then fall back to passed-in item
        if let liveItem = activities.first(where: { $0.id == activity.id }) {
            return liveItem.cheersUserIDs.contains(currentID)
        }
        return activity.cheersUserIDs.contains(currentID)
    }

    // MARK: - Content Reports

    func submitReport(activityID: String, reportedUserID: String, reporterUserID: String, reason: ContentReport.ReportReason, details: String?) async {
        let report = ContentReport(
            reportedActivityID: activityID,
            reportedUserID: reportedUserID,
            reporterUserID: reporterUserID,
            reason: reason,
            details: details
        )

        do {
            let record = report.toCKRecord()
            try await cloudKitManager.saveToPublic(record)
            AppLogger.activity.info("Content report submitted for activity: \(activityID)")

            // Auto-hide: set isGlobalPhoto = 0 so it disappears from everyone's Global feed
            let predicate = NSPredicate(format: "activityID == %@", activityID)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                limit: 1
            )
            if let activityRecord = records.first {
                activityRecord["isGlobalPhoto"] = 0
                try await cloudKitManager.saveToPublic(activityRecord)
                AppLogger.activity.info("Reported activity hidden from global feed: \(activityID)")
            }
        } catch {
            AppLogger.activity.error("Failed to submit report: \(error.localizedDescription)")
        }
    }

    // MARK: - Sharing Preferences

    func updatePreferences(_ preferences: UserSharingPreferences) {
        sharingPreferences = preferences
        savePreferences()
    }

    private func savePreferences() {
        do {
            let data = try JSONEncoder().encode(sharingPreferences)
            UserDefaults.standard.set(data, forKey: preferencesKey)
        } catch {
            AppLogger.activity.error("Failed to save sharing preferences: \(error.localizedDescription)")
        }
    }

    private static func loadPreferences() -> UserSharingPreferences {
        guard let data = UserDefaults.standard.data(forKey: "UserSharingPreferences") else {
            return .default
        }

        do {
            return try JSONDecoder().decode(UserSharingPreferences.self, from: data)
        } catch {
            return .default
        }
    }

    // MARK: - Debug

    #if DEBUG
    @Published var isUsingFakeData = false

    func addTestActivities() {
        isUsingFakeData = true
        activities = [
            // Badge unlocks
            ActivityItem(
                userID: "test1",
                displayName: "DCFan",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-1800),
                payload: ActivityPayload(badgeID: "centurion", badgeTitle: "Centurion", badgeIcon: "shield.fill", badgeRarity: .rare),
                cheersCount: 15,
                cheersUserIDs: ["test2", "test3"]
            ),
            ActivityItem(
                userID: "test4",
                displayName: "SodaQueen",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-5400),
                payload: ActivityPayload(badgeID: "legend", badgeTitle: "Legendary Status", badgeIcon: "crown.fill", badgeRarity: .legendary),
                cheersCount: 42,
                cheersUserIDs: ["test1", "test2", "test3", "test5"]
            ),
            // Streak milestones
            ActivityItem(
                userID: "test2",
                displayName: "CokeZeroKing",
                type: .streakMilestone,
                timestamp: Date().addingTimeInterval(-3600),
                payload: ActivityPayload(streakDays: 100, streakMessage: "Century club!"),
                cheersCount: 28,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "test5",
                displayName: "BubbleMaster",
                type: .streakMilestone,
                timestamp: Date().addingTimeInterval(-14400),
                payload: ActivityPayload(streakDays: 7, streakMessage: "One week strong!"),
                cheersCount: 8,
                cheersUserIDs: []
            ),
            // Drink logs
            ActivityItem(
                userID: "test3",
                displayName: "FountainFinder",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-7200),
                payload: ActivityPayload(drinkType: .mcdonaldsLarge, drinkNote: "Perfect fountain ratio!", hasPhoto: true),
                cheersCount: 6,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "test1",
                displayName: "DCFan",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-10800),
                payload: ActivityPayload(drinkType: .regularCan, drinkNote: nil, hasPhoto: false),
                cheersCount: 2,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "test4",
                displayName: "SodaQueen",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-18000),
                payload: ActivityPayload(drinkType: .chickfilaLarge, drinkNote: "Chick-fil-A hits different", hasPhoto: true),
                cheersCount: 11,
                cheersUserIDs: []
            ),
            // More badge unlocks
            ActivityItem(
                userID: "test3",
                displayName: "FountainFinder",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-21600),
                payload: ActivityPayload(badgeID: "explorer", badgeTitle: "Explorer", badgeIcon: "map.fill", badgeRarity: .uncommon),
                cheersCount: 4,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "test2",
                displayName: "CokeZeroKing",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-43200),
                payload: ActivityPayload(badgeID: "marathon", badgeTitle: "Marathon Sipper", badgeIcon: "figure.run", badgeRarity: .epic),
                cheersCount: 19,
                cheersUserIDs: []
            ),
        ]
    }

    func clearTestActivities() {
        activities = []
        isUsingFakeData = false
    }
    #endif

    // MARK: - Data Management

    /// Clear all local activity data (used for account deletion)
    func clearAllData() {
        activities = []
        #if DEBUG
        isUsingFakeData = false
        #endif
    }
}
