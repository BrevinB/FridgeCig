import Foundation
import CloudKit
import UserNotifications
import UIKit
import os

@MainActor
class NotificationService: ObservableObject {
    @Published var preferences: NotificationPreferences {
        didSet {
            preferences.save()
            Task {
                await updateAllNotifications()
            }
        }
    }
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let cloudKitManager: CloudKitManager
    private var currentUserID: String?
    private var friendIDs: [String] = []
    private var failedSubscriptionRetryInfo: [(recordType: String, predicate: NSPredicate, subscriptionID: String, notificationInfo: CKSubscription.NotificationInfo, options: CKQuerySubscription.Options)] = []
    private var networkObserver: Any?

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let streakReminder = "streak_reminder"
        static let dailySummary = "daily_summary"
        static let weeklySummary = "weekly_summary"
    }

    // MARK: - CloudKit Subscription IDs

    private enum SubscriptionID {
        static func friendRequest(userID: String) -> String { "friend-request-\(userID)" }
        static func friendAccepted(userID: String) -> String { "friend-accepted-\(userID)" }
        static func cheersReceived(userID: String) -> String { "cheers-received-\(userID)" }
        static func friendMilestones(userID: String) -> String { "friend-milestones-\(userID)" }
    }

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
        self.preferences = NotificationPreferences.load()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await updateAuthorizationStatus()
            if granted {
                await registerForRemoteNotifications()
                await updateAllNotifications()
            }
            return granted
        } catch {
            AppLogger.notifications.error("Authorization error: \(error.localizedDescription)")
            return false
        }
    }

    func updateAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Configuration

    func configure(userID: String, friendIDs: [String]) async {
        let userChanged = currentUserID != userID
        let friendsChanged = self.friendIDs != friendIDs

        self.currentUserID = userID
        self.friendIDs = friendIDs

        if userChanged || friendsChanged {
            await updateCloudKitSubscriptions()
        }
    }

    func updateFriends(_ friendIDs: [String]) async {
        let changed = self.friendIDs != friendIDs
        self.friendIDs = friendIDs

        if changed {
            await updateFriendMilestonesSubscription()
        }
    }

    // MARK: - Update All Notifications

    private func updateAllNotifications() async {
        await updateLocalNotifications()
        await updateCloudKitSubscriptions()
    }

    // MARK: - Local Notifications

    private func updateLocalNotifications() async {
        await scheduleStreakReminder()
        await scheduleDailySummary()
        await scheduleWeeklySummary()
    }

    // MARK: - Streak Reminder

    func scheduleStreakReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.streakReminder])

        guard preferences.streakRemindersEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "You haven't logged a drink today. Keep that streak going!"
        content.sound = .default

        // Extract hour and minute from preference time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: preferences.streakReminderTime)
        let minute = calendar.component(.minute, from: preferences.streakReminderTime)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakReminder,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            AppLogger.notifications.info("Scheduled streak reminder for \(hour):\(String(format: "%02d", minute))")
        } catch {
            AppLogger.notifications.error("Failed to schedule streak reminder: \(error.localizedDescription)")
        }
    }

    /// Cancel streak reminder if user has logged a drink today
    func cancelStreakReminderIfNeeded(hasLoggedToday: Bool) {
        if hasLoggedToday {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [NotificationID.streakReminder]
            )
        }
    }

    // MARK: - Daily Summary

    func scheduleDailySummary() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailySummary])

        guard preferences.dailySummaryEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Today's Recap"
        content.body = "See how your day stacked up!"
        content.sound = .default

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: preferences.dailySummaryTime)
        let minute = calendar.component(.minute, from: preferences.dailySummaryTime)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.dailySummary,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            AppLogger.notifications.info("Scheduled daily summary for \(hour):\(String(format: "%02d", minute))")
        } catch {
            AppLogger.notifications.error("Failed to schedule daily summary: \(error.localizedDescription)")
        }
    }

    // MARK: - Weekly Summary

    func scheduleWeeklySummary() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.weeklySummary])

        guard preferences.weeklySummaryEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your Week in Review"
        content.body = "See how your week stacked up!"
        content.sound = .default

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: preferences.weeklySummaryTime)
        let minute = calendar.component(.minute, from: preferences.weeklySummaryTime)

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.weeklySummary,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            AppLogger.notifications.info("Scheduled weekly summary for Sunday \(hour):\(String(format: "%02d", minute))")
        } catch {
            AppLogger.notifications.error("Failed to schedule weekly summary: \(error.localizedDescription)")
        }
    }

    // MARK: - CloudKit Subscriptions

    private func updateCloudKitSubscriptions() async {
        guard let userID = currentUserID else {
            AppLogger.notifications.info("No user ID, skipping CloudKit subscriptions")
            return
        }

        guard cloudKitManager.isAvailable else {
            AppLogger.notifications.info("CloudKit unavailable, deferring subscription setup")
            listenForNetworkRecovery()
            return
        }

        // Clear previous failures before retrying
        failedSubscriptionRetryInfo = []

        await updateFriendRequestSubscription(userID: userID)
        await updateFriendAcceptedSubscription(userID: userID)
        await updateCheersSubscription(userID: userID)
        await updateFriendMilestonesSubscription()

        if !failedSubscriptionRetryInfo.isEmpty {
            AppLogger.notifications.info("\(self.failedSubscriptionRetryInfo.count) subscriptions failed, will retry when network is available")
            listenForNetworkRecovery()
        }
    }

    private func listenForNetworkRecovery() {
        guard networkObserver == nil else { return }
        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkBecameAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.retryFailedSubscriptions()
            }
        }
    }

    func retryFailedSubscriptions() async {
        guard !failedSubscriptionRetryInfo.isEmpty else { return }
        guard cloudKitManager.isAvailable else { return }

        AppLogger.notifications.info("Retrying \(self.failedSubscriptionRetryInfo.count) failed subscriptions")
        let retries = failedSubscriptionRetryInfo
        failedSubscriptionRetryInfo = []

        for info in retries {
            let success = await cloudKitManager.createSubscription(
                recordType: info.recordType,
                predicate: info.predicate,
                subscriptionID: info.subscriptionID,
                notificationInfo: info.notificationInfo,
                options: info.options
            )
            if !success {
                failedSubscriptionRetryInfo.append(info)
            }
        }

        if failedSubscriptionRetryInfo.isEmpty {
            // All succeeded, remove the observer
            if let observer = networkObserver {
                NotificationCenter.default.removeObserver(observer)
                networkObserver = nil
            }
            AppLogger.notifications.info("All subscription retries succeeded")
        } else {
            AppLogger.notifications.info("\(self.failedSubscriptionRetryInfo.count) subscriptions still failing")
        }
    }

    private func updateFriendRequestSubscription(userID: String) async {
        let subscriptionID = SubscriptionID.friendRequest(userID: userID)

        if preferences.friendRequestsEnabled {
            let predicate = NSPredicate(format: "targetID == %@ AND status == %@", userID, "pending")
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.alertLocalizationKey = "New friend request"
            notificationInfo.soundName = "default"
            notificationInfo.shouldBadge = true

            let success = await cloudKitManager.createSubscription(
                recordType: "FriendConnection",
                predicate: predicate,
                subscriptionID: subscriptionID,
                notificationInfo: notificationInfo,
                options: [.firesOnRecordCreation]
            )
            if !success {
                failedSubscriptionRetryInfo.append((recordType: "FriendConnection", predicate: predicate, subscriptionID: subscriptionID, notificationInfo: notificationInfo, options: [.firesOnRecordCreation]))
            }
        } else {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
        }
    }

    private func updateFriendAcceptedSubscription(userID: String) async {
        let subscriptionID = SubscriptionID.friendAccepted(userID: userID)

        if preferences.friendAcceptedEnabled {
            let predicate = NSPredicate(format: "requesterID == %@ AND status == %@", userID, "accepted")
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.alertLocalizationKey = "Friend request accepted"
            notificationInfo.soundName = "default"
            notificationInfo.shouldBadge = true

            let success = await cloudKitManager.createSubscription(
                recordType: "FriendConnection",
                predicate: predicate,
                subscriptionID: subscriptionID,
                notificationInfo: notificationInfo,
                options: [.firesOnRecordUpdate]
            )
            if !success {
                failedSubscriptionRetryInfo.append((recordType: "FriendConnection", predicate: predicate, subscriptionID: subscriptionID, notificationInfo: notificationInfo, options: [.firesOnRecordUpdate]))
            }
        } else {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
        }
    }

    private func updateCheersSubscription(userID: String) async {
        let subscriptionID = SubscriptionID.cheersReceived(userID: userID)

        if preferences.cheersReceivedEnabled {
            let predicate = NSPredicate(format: "userID == %@", userID)
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.alertLocalizationKey = "Someone cheered your activity"
            notificationInfo.soundName = "default"
            notificationInfo.shouldBadge = true

            let success = await cloudKitManager.createSubscription(
                recordType: "ActivityItem",
                predicate: predicate,
                subscriptionID: subscriptionID,
                notificationInfo: notificationInfo,
                options: [.firesOnRecordUpdate]
            )
            if !success {
                failedSubscriptionRetryInfo.append((recordType: "ActivityItem", predicate: predicate, subscriptionID: subscriptionID, notificationInfo: notificationInfo, options: [.firesOnRecordUpdate]))
            }
        } else {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
        }
    }

    private func updateFriendMilestonesSubscription() async {
        guard let userID = currentUserID else { return }
        let subscriptionID = SubscriptionID.friendMilestones(userID: userID)

        if preferences.friendMilestonesEnabled && !friendIDs.isEmpty {
            // Note: CloudKit has limits on IN predicate arrays. For large friend lists,
            // you might need to create multiple subscriptions or use a different approach
            let predicate = NSPredicate(
                format: "userID IN %@ AND (type == %@ OR type == %@)",
                friendIDs, "badgeUnlock", "streakMilestone"
            )
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.alertLocalizationKey = "A friend hit a milestone!"
            notificationInfo.soundName = "default"
            notificationInfo.shouldBadge = true

            let success = await cloudKitManager.createSubscription(
                recordType: "ActivityItem",
                predicate: predicate,
                subscriptionID: subscriptionID,
                notificationInfo: notificationInfo,
                options: [.firesOnRecordCreation]
            )
            if !success {
                failedSubscriptionRetryInfo.append((recordType: "ActivityItem", predicate: predicate, subscriptionID: subscriptionID, notificationInfo: notificationInfo, options: [.firesOnRecordCreation]))
            }
        } else {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
        }
    }

    // MARK: - Push Notification Handling

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return .noData
        }

        // Handle CloudKit subscription notification
        if let queryNotification = notification as? CKQueryNotification,
           let subscriptionID = queryNotification.subscriptionID {

            AppLogger.notifications.debug("Received push for subscription: \(subscriptionID)")

            // Determine notification type based on subscription ID
            if subscriptionID.hasPrefix("friend-request-") {
                await handleFriendRequestNotification(queryNotification)
            } else if subscriptionID.hasPrefix("friend-accepted-") {
                await handleFriendAcceptedNotification(queryNotification)
            } else if subscriptionID.hasPrefix("cheers-received-") {
                await handleCheersNotification(queryNotification)
            } else if subscriptionID.hasPrefix("friend-milestones-") {
                await handleFriendMilestoneNotification(queryNotification)
            }

            return .newData
        }

        return .noData
    }

    private func handleFriendRequestNotification(_ notification: CKQueryNotification) async {
        // Fetch the friend connection record to get requester info
        guard let recordID = notification.recordID else { return }

        do {
            if let record = try await cloudKitManager.fetchFromPublic(recordID: recordID) {
                let requesterID = record["requesterID"] as? String ?? ""

                // Fetch requester profile to get their display name
                if let profile = try await cloudKitManager.fetchUserProfile(byUserID: requesterID) {
                    let displayName = profile["displayName"] as? String ?? "Someone"
                    await showLocalNotification(
                        title: "New Friend Request",
                        body: "\(displayName) wants to be your friend!",
                        categoryIdentifier: "FRIEND_REQUEST"
                    )
                }
            }
        } catch {
            AppLogger.notifications.error("Error handling friend request: \(error.localizedDescription)")
        }
    }

    private func handleFriendAcceptedNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else { return }

        do {
            if let record = try await cloudKitManager.fetchFromPublic(recordID: recordID) {
                let targetID = record["targetID"] as? String ?? ""

                if let profile = try await cloudKitManager.fetchUserProfile(byUserID: targetID) {
                    let displayName = profile["displayName"] as? String ?? "Someone"
                    await showLocalNotification(
                        title: "Friend Request Accepted",
                        body: "\(displayName) accepted your friend request!",
                        categoryIdentifier: "FRIEND_ACCEPTED"
                    )
                }
            }
        } catch {
            AppLogger.notifications.error("Error handling friend accepted: \(error.localizedDescription)")
        }
    }

    private func handleCheersNotification(_ notification: CKQueryNotification) async {
        await showLocalNotification(
            title: "New Cheers!",
            body: "Someone cheered your activity!",
            categoryIdentifier: "CHEERS"
        )
    }

    private func handleFriendMilestoneNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else { return }

        do {
            if let record = try await cloudKitManager.fetchFromPublic(recordID: recordID) {
                let displayName = record["displayName"] as? String ?? "A friend"
                let activityType = record["type"] as? String ?? ""

                let body: String
                if activityType == "badgeUnlock" {
                    body = "\(displayName) earned a new badge!"
                } else if activityType == "streakMilestone" {
                    body = "\(displayName) hit a streak milestone!"
                } else {
                    body = "\(displayName) achieved something awesome!"
                }

                await showLocalNotification(
                    title: "Friend Milestone",
                    body: body,
                    categoryIdentifier: "FRIEND_MILESTONE"
                )
            }
        } catch {
            AppLogger.notifications.error("Error handling friend milestone: \(error.localizedDescription)")
        }
    }

    private func showLocalNotification(title: String, body: String, categoryIdentifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            AppLogger.notifications.error("Failed to show notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug

    #if DEBUG
    func testFriendRequestNotification() async {
        await showLocalNotification(
            title: "New Friend Request",
            body: "TestUser wants to be your friend!",
            categoryIdentifier: "FRIEND_REQUEST"
        )
    }

    func testCheersNotification() async {
        await showLocalNotification(
            title: "New Cheers!",
            body: "Someone cheered your activity!",
            categoryIdentifier: "CHEERS"
        )
    }

    func testFriendMilestoneNotification() async {
        await showLocalNotification(
            title: "Friend Milestone",
            body: "TestFriend earned a new badge!",
            categoryIdentifier: "FRIEND_MILESTONE"
        )
    }

    func testStreakReminder() async {
        await showLocalNotification(
            title: "Don't break your streak!",
            body: "You haven't logged a drink today. Keep that streak going!",
            categoryIdentifier: "STREAK_REMINDER"
        )
    }

    func listPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        AppLogger.notifications.debug("Pending notifications (\(requests.count)):")
        for request in requests {
            AppLogger.notifications.debug("  - \(request.identifier): \(request.content.title)")
        }
    }

    func listCloudKitSubscriptions() async {
        let subscriptions = await cloudKitManager.fetchAllSubscriptions()
        AppLogger.notifications.debug("CloudKit subscriptions (\(subscriptions.count)):")
        for subscription in subscriptions {
            AppLogger.notifications.debug("  - \(subscription.subscriptionID)")
        }
    }
    #endif
}
