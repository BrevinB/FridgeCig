import UIKit
import CloudKit
import UserNotifications

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
        print("[AppDelegate] Registered for remote notifications with token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
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
        case "CHEERS":
            NotificationCenter.default.post(name: .navigateToActivityFeed, object: nil)
        case "STREAK_REMINDER":
            NotificationCenter.default.post(name: .navigateToAddDrink, object: nil)
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

        center.setNotificationCategories([
            friendRequestCategory,
            friendAcceptedCategory,
            cheersCategory,
            friendMilestoneCategory,
            streakReminderCategory
        ])
    }
}

// MARK: - Navigation Notification Names

extension Notification.Name {
    static let navigateToFriendRequests = Notification.Name("navigateToFriendRequests")
    static let navigateToActivityFeed = Notification.Name("navigateToActivityFeed")
    static let navigateToAddDrink = Notification.Name("navigateToAddDrink")
}
