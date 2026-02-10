import Foundation

/// Data manager for the Watch app - reads from local storage synced via WatchConnectivity
struct WatchDataManager {
    static let entriesKey = "DietCokeEntries"
    static let appGroupID = "group.co.brevinb.fridgecig"
    static let lastEntryTimeKey = "lastEntryTime"
    static let minimumEntryInterval: TimeInterval = 120

    // Try app group first, fall back to standard defaults
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }

    // MARK: - Rate Limiting

    static func canAddEntry() -> (allowed: Bool, message: String?) {
        if let lastTime = defaults.object(forKey: lastEntryTimeKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumEntryInterval {
                return (false, "Please wait a moment before adding another drink.")
            }
        }
        return (true, nil)
    }

    static func recordEntryAdded() {
        defaults.set(Date(), forKey: lastEntryTimeKey)
    }

    // MARK: - Read Entries

    static func getEntries() -> [DrinkEntry] {
        guard let data = defaults.data(forKey: entriesKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([DrinkEntry].self, from: data)
        } catch {
            print("WatchDataManager: Failed to decode entries: \(error)")
            return []
        }
    }

    static func saveEntries(_ entries: [DrinkEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
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

    // MARK: - Add Entry (saves locally and syncs to iPhone)

    static func addEntry(_ entry: DrinkEntry) {
        var entries = getEntries()
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        saveEntries(entries)

        // Record for rate limiting
        recordEntryAdded()

        // Send to iPhone for syncing
        Task { @MainActor in
            WatchConnectivityManager.shared.sendEntryToPhone(entry)
        }
    }
}
