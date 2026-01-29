import Foundation

struct NotificationPreferences: Codable {
    // MARK: - Push Notification Preferences
    var friendRequestsEnabled: Bool
    var friendAcceptedEnabled: Bool
    var cheersReceivedEnabled: Bool
    var friendMilestonesEnabled: Bool

    // MARK: - Local Notification Preferences
    var streakRemindersEnabled: Bool
    var streakReminderTime: Date
    var dailySummaryEnabled: Bool
    var dailySummaryTime: Date
    var weeklySummaryEnabled: Bool
    var weeklySummaryTime: Date

    init(
        friendRequestsEnabled: Bool = true,
        friendAcceptedEnabled: Bool = true,
        cheersReceivedEnabled: Bool = true,
        friendMilestonesEnabled: Bool = true,
        streakRemindersEnabled: Bool = true,
        streakReminderTime: Date = NotificationPreferences.defaultStreakReminderTime,
        dailySummaryEnabled: Bool = false,
        dailySummaryTime: Date = NotificationPreferences.defaultDailySummaryTime,
        weeklySummaryEnabled: Bool = true,
        weeklySummaryTime: Date = NotificationPreferences.defaultWeeklySummaryTime
    ) {
        self.friendRequestsEnabled = friendRequestsEnabled
        self.friendAcceptedEnabled = friendAcceptedEnabled
        self.cheersReceivedEnabled = cheersReceivedEnabled
        self.friendMilestonesEnabled = friendMilestonesEnabled
        self.streakRemindersEnabled = streakRemindersEnabled
        self.streakReminderTime = streakReminderTime
        self.dailySummaryEnabled = dailySummaryEnabled
        self.dailySummaryTime = dailySummaryTime
        self.weeklySummaryEnabled = weeklySummaryEnabled
        self.weeklySummaryTime = weeklySummaryTime
    }

    // MARK: - Default Times

    /// Default streak reminder time: 8:00 PM
    static var defaultStreakReminderTime: Date {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Default daily summary time: 9:00 PM
    static var defaultDailySummaryTime: Date {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Default weekly summary time: Sunday 10:00 AM
    static var defaultWeeklySummaryTime: Date {
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static let `default` = NotificationPreferences()
}

// MARK: - Persistence

extension NotificationPreferences {
    private static let storageKey = "NotificationPreferences"

    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
