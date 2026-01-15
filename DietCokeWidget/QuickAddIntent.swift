import AppIntents
import WidgetKit

struct QuickAddDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Diet Coke"
    static var description = IntentDescription("Adds a regular can of Diet Coke")

    func perform() async throws -> some IntentResult {
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

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

struct QuickAddBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add 20oz Bottle"
    static var description = IntentDescription("Adds a 20oz bottle of Diet Coke")

    func perform() async throws -> some IntentResult {
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

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

