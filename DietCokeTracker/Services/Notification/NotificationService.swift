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
    private var didRemoveLegacySubscriptionsFor: Set<String> = []

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let streakReminder = "streak_reminder"
        static let dailySummary = "daily_summary"
        static let weeklySummary = "weekly_summary"
    }

    // MARK: - CloudKit Subscription IDs

    private enum SubscriptionID {
        static func socialActivity(userID: String) -> String { "social-activity-\(userID)" }
        static func friendMilestones(userID: String) -> String { "friend-milestones-\(userID)" }

        /// Superseded by `socialActivity`, which delivers the same events with
        /// the actor's name attached and without the duplicate banners these
        /// produced. Deleted server-side on the next configure.
        static func legacy(userID: String) -> [String] {
            [
                "friend-request-\(userID)",
                "friend-accepted-\(userID)",
                "cheers-received-\(userID)"
            ]
        }
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
        content.categoryIdentifier = "DAILY_SUMMARY"

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

        await removeLegacySubscriptions(userID: userID)
        await updateSocialActivitySubscription(userID: userID)
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

    /// Tears down the per-event subscriptions that `socialActivity` replaced.
    /// Without this, upgraded users keep receiving the old generic banners
    /// alongside the new named ones.
    ///
    /// Runs at most once per user per launch — subscription updates happen on
    /// every preference and friend-list change, and these deletes are pure
    /// no-ops after the first pass.
    private func removeLegacySubscriptions(userID: String) async {
        guard !didRemoveLegacySubscriptionsFor.contains(userID) else { return }
        didRemoveLegacySubscriptionsFor.insert(userID)

        for subscriptionID in SubscriptionID.legacy(userID: userID) {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
        }
    }

    /// One subscription for every social event addressed to this user.
    ///
    /// `SocialNotification` records carry the actor's name and a ready-made
    /// body, and CloudKit substitutes those fields straight into the alert. That
    /// turns "Someone cheered your activity" into "Alex — cheered your post 🔥"
    /// without a server or a silent-push round trip.
    private func updateSocialActivitySubscription(userID: String) async {
        let subscriptionID = SubscriptionID.socialActivity(userID: userID)

        guard preferences.socialActivityEnabled else {
            await cloudKitManager.removeSubscription(subscriptionID: subscriptionID)
            return
        }

        let predicate = NSPredicate(format: "recipientID == %@", userID)
        let notificationInfo = CKSubscription.NotificationInfo()
        // The keys double as the format strings; with no matching entry in a
        // strings file, iOS falls back to the key itself and substitutes the
        // named record fields.
        notificationInfo.titleLocalizationKey = "%1$@"
        notificationInfo.titleLocalizationArgs = ["actorName"]
        notificationInfo.alertLocalizationKey = "%1$@"
        notificationInfo.alertLocalizationArgs = ["bodyText"]
        notificationInfo.category = "SOCIAL"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true

        let success = await cloudKitManager.createSubscription(
            recordType: SocialNotification.recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            notificationInfo: notificationInfo,
            options: [.firesOnRecordCreation]
        )
        if !success {
            failedSubscriptionRetryInfo.append((recordType: SocialNotification.recordType, predicate: predicate, subscriptionID: subscriptionID, notificationInfo: notificationInfo, options: [.firesOnRecordCreation]))
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
            // Same field-substitution trick as the social subscription, so the
            // banner names the friend and the achievement without the app
            // posting a second one on top.
            notificationInfo.titleLocalizationKey = "%1$@"
            notificationInfo.titleLocalizationArgs = ["displayName"]
            notificationInfo.alertLocalizationKey = "%1$@"
            notificationInfo.alertLocalizationArgs = ["milestoneText"]
            notificationInfo.category = "FRIEND_MILESTONE"
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
            if subscriptionID.hasPrefix("social-activity-") {
                handleSocialActivityNotification()
            }

            return .newData
        }

        return .noData
    }

    /// CloudKit renders these alerts from the record's own fields, so there's
    /// nothing to display here — just tell the inbox to refetch so the badge
    /// and list are current when the user opens the app.
    private func handleSocialActivityNotification() {
        NotificationCenter.default.post(name: .socialInboxDidChange, object: nil)
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

    /// Mirrors the shape a real social push takes: actor name as the title,
    /// the event as the body.
    func testCheersNotification() async {
        await showLocalNotification(
            title: "TestFriend",
            body: "fired up your post 🔥",
            categoryIdentifier: "SOCIAL"
        )
    }

    func testFriendMilestoneNotification() async {
        await showLocalNotification(
            title: "TestFriend",
            body: "earned the Centurion badge 🏆",
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
