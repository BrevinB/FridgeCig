import Foundation

struct NotificationPreferences: Codable {
    // MARK: - Push Notification Preferences

    /// Covers reactions, comments, nudges, and friend requests — everything a
    /// person does *to you*. They share one CloudKit subscription, so they
    /// share one switch.
    var socialActivityEnabled: Bool
    var friendMilestonesEnabled: Bool

    // MARK: - Local Notification Preferences
    var streakRemindersEnabled: Bool
    var streakReminderTime: Date
    var dailySummaryEnabled: Bool
    var dailySummaryTime: Date
    var weeklySummaryEnabled: Bool
    var weeklySummaryTime: Date

    init(
        socialActivityEnabled: Bool = true,
        friendMilestonesEnabled: Bool = true,
        streakRemindersEnabled: Bool = true,
        streakReminderTime: Date = NotificationPreferences.defaultStreakReminderTime,
        dailySummaryEnabled: Bool = false,
        dailySummaryTime: Date = NotificationPreferences.defaultDailySummaryTime,
        weeklySummaryEnabled: Bool = true,
        weeklySummaryTime: Date = NotificationPreferences.defaultWeeklySummaryTime
    ) {
        self.socialActivityEnabled = socialActivityEnabled
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

    /// Decoded field by field so adding or retiring a preference doesn't throw
    /// away everything the user had configured. `socialActivityEnabled`
    /// inherits the old per-event flags when upgrading: if any of them was on,
    /// the combined switch stays on.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = NotificationPreferences.default

        if let combined = try container.decodeIfPresent(Bool.self, forKey: .socialActivityEnabled) {
            socialActivityEnabled = combined
        } else {
            var legacyValues: [Bool] = []
            if let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self) {
                for key in LegacyCodingKeys.allCases {
                    let raw = try? legacyContainer.decodeIfPresent(Bool.self, forKey: key)
                    if let value = raw ?? nil {
                        legacyValues.append(value)
                    }
                }
            }
            // Only opt someone out if they had explicitly turned every social
            // push off before the switches were merged.
            socialActivityEnabled = legacyValues.isEmpty
                ? defaults.socialActivityEnabled
                : legacyValues.contains(true)
        }

        friendMilestonesEnabled = try container.decodeIfPresent(Bool.self, forKey: .friendMilestonesEnabled) ?? defaults.friendMilestonesEnabled
        streakRemindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .streakRemindersEnabled) ?? defaults.streakRemindersEnabled
        streakReminderTime = try container.decodeIfPresent(Date.self, forKey: .streakReminderTime) ?? defaults.streakReminderTime
        dailySummaryEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailySummaryEnabled) ?? defaults.dailySummaryEnabled
        dailySummaryTime = try container.decodeIfPresent(Date.self, forKey: .dailySummaryTime) ?? defaults.dailySummaryTime
        weeklySummaryEnabled = try container.decodeIfPresent(Bool.self, forKey: .weeklySummaryEnabled) ?? defaults.weeklySummaryEnabled
        weeklySummaryTime = try container.decodeIfPresent(Date.self, forKey: .weeklySummaryTime) ?? defaults.weeklySummaryTime
    }

    private enum LegacyCodingKeys: String, CodingKey, CaseIterable {
        case friendRequestsEnabled
        case friendAcceptedEnabled
        case cheersReceivedEnabled
    }
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
