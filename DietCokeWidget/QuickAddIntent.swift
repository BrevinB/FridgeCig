import AppIntents
import WidgetKit

struct QuickAddDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add DC"
    static var description = IntentDescription("Adds a regular can of DC")

    func perform() async throws -> some IntentResult {
        // Check rate limiting
        let (allowed, _) = SharedDataManager.canAddEntry()
        guard allowed else {
            // Silently fail if rate limited (widget can't show alerts)
            return .result()
        }

        // Add a regular can entry
        let entry = DrinkEntry(type: .regularCan)

        // Save to shared UserDefaults
        guard let defaults = UserDefaults(suiteName: SharedDataManager.appGroupID) else {
            return .result()
        }

        var entries: [DrinkEntry] = []
        if let data = defaults.data(forKey: SharedDataManager.entriesKey) {
            entries = (try? JSONDecoder().decode([DrinkEntry].self, from: data)) ?? []
        }

        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }

        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: SharedDataManager.entriesKey)
        }

        // Record the entry for rate limiting
        SharedDataManager.recordEntryAdded()

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

struct QuickAddBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add 20oz Bottle"
    static var description = IntentDescription("Adds a 20oz bottle of DC")

    func perform() async throws -> some IntentResult {
        // Check rate limiting
        let (allowed, _) = SharedDataManager.canAddEntry()
        guard allowed else {
            return .result()
        }

        let entry = DrinkEntry(type: .bottle20oz)

        guard let defaults = UserDefaults(suiteName: SharedDataManager.appGroupID) else {
            return .result()
        }

        var entries: [DrinkEntry] = []
        if let data = defaults.data(forKey: SharedDataManager.entriesKey) {
            entries = (try? JSONDecoder().decode([DrinkEntry].self, from: data)) ?? []
        }

        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }

        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: SharedDataManager.entriesKey)
        }

        // Record the entry for rate limiting
        SharedDataManager.recordEntryAdded()

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

