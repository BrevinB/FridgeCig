import UIKit
import CloudKit
import UserNotifications
import os

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var notificationService: NotificationService?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Register notification categories for actions
        registerNotificationCategories()

        return true
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.notifications.debug("Registered for remote notifications with token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppLogger.notifications.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Remote Notification Handling

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle CloudKit push notifications
        Task { @MainActor in
            if let notificationService = notificationService {
                let result = await notificationService.handleRemoteNotification(userInfo: userInfo)
                completionHandler(result)
            } else {
                completionHandler(.noData)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap/action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        // Post notification for navigation based on category
        switch categoryIdentifier {
        case "FRIEND_REQUEST":
            NotificationCenter.default.post(name: .navigateToFriendRequests, object: nil)
        case "FRIEND_ACCEPTED", "FRIEND_MILESTONE":
            NotificationCenter.default.post(name: .navigateToActivityFeed, object: nil)
        case "CHEERS", "SOCIAL":
            // Every social event now lands in the inbox, so that's where a tap
            // should go — the user can see who did what.
            NotificationCenter.default.post(name: .navigateToSocialInbox, object: nil)
        case "STREAK_REMINDER":
            NotificationCenter.default.post(name: .navigateToAddDrink, object: nil)
        case "DAILY_SUMMARY":
            Task { @MainActor in
                DeepLinkHandler.shared.shouldShowTodayRecap = true
            }
        default:
            break
        }

        completionHandler()
    }

    // MARK: - Notification Categories

    private func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()

        // Friend Request category with accept/decline actions
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_FRIEND",
            title: "Accept",
            options: [.foreground]
        )
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_FRIEND",
            title: "Decline",
            options: [.destructive]
        )
        let friendRequestCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )

        // Other categories without actions
        let friendAcceptedCategory = UNNotificationCategory(
            identifier: "FRIEND_ACCEPTED",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let cheersCategory = UNNotificationCategory(
            identifier: "CHEERS",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        // Reactions, comments, nudges, and friend activity all arrive under one
        // category now that they share a single inbox.
        let socialCategory = UNNotificationCategory(
            identifier: "SOCIAL",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let friendMilestoneCategory = UNNotificationCategory(
            identifier: "FRIEND_MILESTONE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let streakReminderCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let dailySummaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            friendRequestCategory,
            friendAcceptedCategory,
            cheersCategory,
            socialCategory,
            friendMilestoneCategory,
            streakReminderCategory,
            dailySummaryCategory
        ])
    }
}

// MARK: - Navigation Notification Names

extension Notification.Name {
    static let navigateToFriendRequests = Notification.Name("navigateToFriendRequests")
    static let navigateToActivityFeed = Notification.Name("navigateToActivityFeed")
    static let navigateToAddDrink = Notification.Name("navigateToAddDrink")
    /// Open the social inbox (bell) — posted when a social push is tapped.
    static let navigateToSocialInbox = Notification.Name("navigateToSocialInbox")
    /// A social push arrived; anything showing the inbox should refetch.
    static let socialInboxDidChange = Notification.Name("socialInboxDidChange")
}
