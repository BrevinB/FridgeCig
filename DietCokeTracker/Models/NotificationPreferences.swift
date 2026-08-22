import Foundation

struct NotificationPreferences: Codable {
    // MARK: - Push Notification Preferences
    var friendRequestsEnabled: Bool
    var friendAcceptedEnabled: Bool
    var cheersReceivedEnabled: Bool
    var friendMilestonesEnabled: Bool
    var leaderboardUpdatesEnabled: Bool

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
        leaderboardUpdatesEnabled: Bool = true,
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
        self.leaderboardUpdatesEnabled = leaderboardUpdatesEnabled
        self.streakRemindersEnabled = streakRemindersEnabled
        self.streakReminderTime = streakReminderTime
        self.dailySummaryEnabled = dailySummaryEnabled
        self.dailySummaryTime = dailySummaryTime
        self.weeklySummaryEnabled = weeklySummaryEnabled
        self.weeklySummaryTime = weeklySummaryTime
    }

    // Custom decoding so saved data from before leaderboardUpdatesEnabled
    // existed doesn't fail to decode (which would reset all preferences).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        friendRequestsEnabled = try container.decode(Bool.self, forKey: .friendRequestsEnabled)
        friendAcceptedEnabled = try container.decode(Bool.self, forKey: .friendAcceptedEnabled)
        cheersReceivedEnabled = try container.decode(Bool.self, forKey: .cheersReceivedEnabled)
        friendMilestonesEnabled = try container.decode(Bool.self, forKey: .friendMilestonesEnabled)
        leaderboardUpdatesEnabled = try container.decodeIfPresent(Bool.self, forKey: .leaderboardUpdatesEnabled) ?? true
        streakRemindersEnabled = try container.decode(Bool.self, forKey: .streakRemindersEnabled)
        streakReminderTime = try container.decode(Date.self, forKey: .streakReminderTime)
        dailySummaryEnabled = try container.decode(Bool.self, forKey: .dailySummaryEnabled)
        dailySummaryTime = try container.decode(Date.self, forKey: .dailySummaryTime)
        weeklySummaryEnabled = try container.decode(Bool.self, forKey: .weeklySummaryEnabled)
        weeklySummaryTime = try container.decode(Date.self, forKey: .weeklySummaryTime)
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
