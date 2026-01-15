import Foundation

struct SharedDataManager {
    static let appGroupID = "group.co.brevinb.fridgecig"
    static let entriesKey = "DietCokeEntries"
    static let defaultBrandKey = "defaultBeverageBrand"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
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
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: entriesKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([DrinkEntry].self, from: data)
        } catch {
            print("SharedDataManager: Failed to decode entries: \(error)")
            return []
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
}
