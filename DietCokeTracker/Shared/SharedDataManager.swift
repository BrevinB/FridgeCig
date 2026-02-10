import Foundation
import os

struct SharedDataManager {
    static let appGroupID = "group.co.brevinb.fridgecig"
    static let entriesKey = "DietCokeEntries"
    static let defaultBrandKey = "defaultBeverageBrand"
    static let lastEntryTimeKey = "lastEntryTime"

    /// Serial queue for coordinated access to shared data between app, widgets, and watch extension
    private static let accessQueue = DispatchQueue(label: "com.fridgecig.shareddata", qos: .userInitiated)

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Rate Limiting

    /// Minimum seconds between entries (2 minutes)
    static let minimumEntryInterval: TimeInterval = 120

    /// Check if we can add a new entry (rate limiting)
    static func canAddEntry() -> (allowed: Bool, message: String?) {
        guard let defaults = sharedDefaults else {
            return (true, nil)
        }

        // Check minimum interval
        if let lastTime = defaults.object(forKey: lastEntryTimeKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumEntryInterval {
                return (false, "Please wait a moment before adding another drink.")
            }
        }

        return (true, nil)
    }

    /// Record that an entry was just added
    static func recordEntryAdded() {
        sharedDefaults?.set(Date(), forKey: lastEntryTimeKey)
    }

    // MARK: - User Preferences

    static func getDefaultBrand() -> BeverageBrand {
        guard let defaults = sharedDefaults,
              let savedValue = defaults.string(forKey: defaultBrandKey),
              let brand = BeverageBrand(rawValue: savedValue) else {
            return .dietCoke
        }
        return brand
    }

    // MARK: - Read Data for Widgets

    static func getEntries() -> [DrinkEntry] {
        accessQueue.sync {
            guard let defaults = sharedDefaults,
                  let data = defaults.data(forKey: entriesKey) else {
                return []
            }

            do {
                return try JSONDecoder().decode([DrinkEntry].self, from: data)
            } catch {
                Logger(subsystem: Bundle.main.bundleIdentifier ?? "co.brevinb.fridgecig", category: "Store").error("SharedDataManager: Failed to decode entries: \(error.localizedDescription)")
                return []
            }
        }
    }

    static func getTodayEntries() -> [DrinkEntry] {
        getEntries().filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    static func getTodayCount() -> Int {
        getTodayEntries().count
    }

    static func getTodayOunces() -> Double {
        getTodayEntries().reduce(0) { $0 + $1.ounces }
    }

    static func getStreak() -> Int {
        let entries = getEntries()
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasEntry = entries.contains { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: checkDate)
            }

            if hasEntry {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    static func getThisWeekCount() -> Int {
        getEntries().filter { entry in
            Calendar.current.isDate(entry.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }

    static func getLast7DaysData() -> [(date: Date, count: Int, ounces: Double)] {
        let entries = getEntries()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return nil
            }
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            return (date: date, count: dayEntries.count, ounces: dayEntries.reduce(0) { $0 + $1.ounces })
        }.reversed()
    }

    // MARK: - Graph Widget Helpers

    /// Get the maximum count from the last 7 days for scaling
    static func getLast7DaysMaxCount() -> Int {
        let data = getLast7DaysData()
        return data.map { $0.count }.max() ?? 1
    }

    /// Get the maximum ounces from the last 7 days for scaling
    static func getLast7DaysMaxOunces() -> Double {
        let data = getLast7DaysData()
        return data.map { $0.ounces }.max() ?? 1.0
    }

    /// Get totals for the last 7 days
    static func getLast7DaysTotals() -> (count: Int, ounces: Double) {
        let data = getLast7DaysData()
        let totalCount = data.reduce(0) { $0 + $1.count }
        let totalOunces = data.reduce(0) { $0 + $1.ounces }
        return (count: totalCount, ounces: totalOunces)
    }

    // MARK: - Streak Widget Helpers

    /// Milestone thresholds for streak achievements
    static let streakMilestones = [7, 14, 30, 60, 90, 100, 180, 365]

    /// Get current streak milestone information
    static func getStreakMilestoneInfo() -> (current: Int, next: Int, progress: Double) {
        let streak = getStreak()

        // Find the next milestone
        let nextMilestone = streakMilestones.first { $0 > streak } ?? (streak + 30)

        // Find the previous milestone (or 0 if none)
        let previousMilestone = streakMilestones.reversed().first { $0 <= streak } ?? 0

        // Calculate progress towards next milestone
        let range = nextMilestone - previousMilestone
        let progress = range > 0 ? Double(streak - previousMilestone) / Double(range) : 1.0

        return (current: streak, next: nextMilestone, progress: min(progress, 1.0))
    }

    /// Check if current streak is exactly on a milestone
    static func isOnMilestone() -> Bool {
        let streak = getStreak()
        return streakMilestones.contains(streak)
    }

    /// Get encouragement text based on streak progress
    static func getStreakEncouragement() -> String {
        let info = getStreakMilestoneInfo()
        let daysToGo = info.next - info.current

        if daysToGo <= 1 {
            return "Almost there!"
        } else if daysToGo <= 3 {
            return "So close!"
        } else if daysToGo <= 7 {
            return "Keep it up!"
        } else {
            return "\(daysToGo) days to go"
        }
    }

    // MARK: - Average Calculations

    /// Get average daily count over the last 30 days
    static func getAverageDailyCount() -> Double {
        let entries = getEntries()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return 0
        }

        let recentEntries = entries.filter { $0.timestamp >= thirtyDaysAgo }
        let daysWithEntries = Set(recentEntries.map { calendar.startOfDay(for: $0.timestamp) })

        guard !daysWithEntries.isEmpty else { return 0 }

        return Double(recentEntries.count) / Double(min(30, daysWithEntries.count))
    }

    /// Get average daily ounces over the last 30 days
    static func getAverageDailyOunces() -> Double {
        let entries = getEntries()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return 0
        }

        let recentEntries = entries.filter { $0.timestamp >= thirtyDaysAgo }
        let daysWithEntries = Set(recentEntries.map { calendar.startOfDay(for: $0.timestamp) })

        guard !daysWithEntries.isEmpty else { return 0 }

        let totalOunces = recentEntries.reduce(0) { $0 + $1.ounces }
        return totalOunces / Double(min(30, daysWithEntries.count))
    }
}
