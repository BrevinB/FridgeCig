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

    private let cloudKitManager: CloudKitManager
    private let preferencesKey = "UserSharingPreferences"
    private var friendIDs: [String] = []
    private var currentUserID: String?

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
        self.sharingPreferences = Self.loadPreferences()
    }

    // MARK: - Configure

    func configure(currentUserID: String, friendIDs: [String]) {
        self.currentUserID = currentUserID
        self.friendIDs = friendIDs
    }

    // MARK: - Fetch Activities

    func fetchActivities() async {
        AppLogger.activity.debug("fetchActivities called")
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

        isLoading = true
        defer { isLoading = false }

        do {
            let records = try await fetchActivityRecords()
            AppLogger.activity.info("Fetched \(records.count) records from CloudKit")

            let fetchedActivities = records.compactMap { ActivityItem(from: $0) }
            AppLogger.activity.debug("Parsed \(fetchedActivities.count) activities")

            // Merge fetched activities with local ones (keep local activities that aren't in CloudKit yet)
            let fetchedIDs = Set(fetchedActivities.map { $0.id })
            let localOnlyActivities = activities.filter { !fetchedIDs.contains($0.id) }
            AppLogger.activity.debug("Local-only activities: \(localOnlyActivities.count)")

            // Combine and sort by timestamp
            activities = (fetchedActivities + localOnlyActivities)
                .sorted { $0.timestamp > $1.timestamp }
            AppLogger.activity.info("Total activities after merge: \(self.activities.count)")
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
            isPremium: isPremium
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
            isPremium: isPremium
        )

        await postActivity(activity)
    }

    func postDrinkActivity(type: DrinkType, note: String?, photo: UIImage?, userID: String, displayName: String, entryID: String, isPremium: Bool = false) async {
        AppLogger.activity.debug("postDrinkActivity called for type: \(type.displayName)")
        guard sharingPreferences.shareDrinkLogs else {
            AppLogger.activity.debug("Drink sharing disabled, skipping")
            return
        }

        let hasPhoto = photo != nil
        var photoURL: String? = nil

        // Upload photo if user enabled photo sharing and has a photo
        if let photo = photo, sharingPreferences.showPhotosInFeed {
            photoURL = await uploadPhoto(photo)
        }

        let activity = ActivityItem(
            userID: userID,
            displayName: displayName,
            type: .drinkLog,
            payload: .forDrink(type: type, note: note, hasPhoto: hasPhoto, photoURL: photoURL, entryID: entryID),
            isPremium: isPremium
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

        // Delete from CloudKit
        do {
            // Find the activity record by searching for matching entryID in payload
            // We need to fetch activities for this user and find the one with matching entryID
            let predicate = NSPredicate(format: "userID == %@", userID)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                limit: 100
            )

            // Find records that match the entryID
            for record in records {
                if let payloadJSON = record["payloadJSON"] as? String,
                   let payloadData = payloadJSON.data(using: .utf8),
                   let payload = try? JSONDecoder().decode(ActivityPayload.self, from: payloadData),
                   payload.drinkEntryID == entryID {
                    // Delete this record
                    try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
                    AppLogger.activity.info("Deleted activity from CloudKit for entryID: \(entryID)")
                    break
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
        do {
            let recordID = CKRecord.ID(recordName: recordName)
            guard let record = try await cloudKitManager.fetchFromPublic(recordID: recordID),
                  let asset = record["photo"] as? CKAsset,
                  let fileURL = asset.fileURL,
                  let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            AppLogger.activity.error("Failed to fetch photo: \(error.localizedDescription)")
            return nil
        }
    }

    private func postActivity(_ activity: ActivityItem) async {
        AppLogger.activity.debug("Posting activity: \(activity.type.rawValue) by \(activity.displayName)")

        // Add to local list immediately (optimistic update)
        activities.insert(activity, at: 0)

        // Try to save to CloudKit
        do {
            let record = activity.toCKRecord()
            try await cloudKitManager.saveToPublic(record)
            AppLogger.activity.info("Activity posted to CloudKit successfully")
        } catch {
            AppLogger.activity.error("Failed to post activity to CloudKit: \(error.localizedDescription)")
            // Activity still shows locally even if CloudKit fails
        }
    }

    // MARK: - Cheers (Reactions)

    func toggleCheers(for activity: ActivityItem) async {
        guard let currentID = currentUserID else { return }

        // Find the activity in our list
        guard let index = activities.firstIndex(where: { $0.id == activity.id }) else { return }

        var updatedActivity = activities[index]

        if updatedActivity.cheersUserIDs.contains(currentID) {
            // Remove cheers
            updatedActivity.cheersUserIDs.removeAll { $0 == currentID }
            updatedActivity.cheersCount = max(0, updatedActivity.cheersCount - 1)
        } else {
            // Add cheers
            updatedActivity.cheersUserIDs.append(currentID)
            updatedActivity.cheersCount += 1
        }

        // Update local state immediately
        activities[index] = updatedActivity

        // Sync to cloud
        do {
            // We need to fetch the existing record to update it
            let predicate = NSPredicate(format: "activityID == %@", activity.id.uuidString)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                limit: 1
            )

            if let existingRecord = records.first {
                existingRecord["cheersCount"] = updatedActivity.cheersCount
                existingRecord["cheersUserIDs"] = updatedActivity.cheersUserIDs
                try await cloudKitManager.saveToPublic(existingRecord)
            }
        } catch {
            AppLogger.activity.error("Failed to update cheers: \(error.localizedDescription)")
        }
    }

    func hasUserCheered(_ activity: ActivityItem) -> Bool {
        guard let currentID = currentUserID else { return false }
        return activity.cheersUserIDs.contains(currentID)
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
