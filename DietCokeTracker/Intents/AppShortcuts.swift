import AppIntents
import WidgetKit

// MARK: - Show Today Count Intent

struct ShowTodayCountIntent: AppIntent {
    static var title: LocalizedStringResource = "How many Diet Cokes today"
    static var description = IntentDescription("Check how many Diet Cokes you've had today")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let count = SharedDataManager.getTodayCount()
        let ounces = SharedDataManager.getTodayOunces()

        if count == 0 {
            return .result(dialog: "You haven't had any Diet Cokes today yet.")
        } else if count == 1 {
            return .result(dialog: "You've had 1 Diet Coke today (\(Int(ounces)) oz).")
        } else {
            return .result(dialog: "You've had \(count) Diet Cokes today (\(Int(ounces)) oz).")
        }
    }
}

// MARK: - Show Streak Intent

struct ShowStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Show my streak"
    static var description = IntentDescription("Check your current Diet Coke streak")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let streak = SharedDataManager.getStreak()

        if streak == 0 {
            return .result(dialog: "You don't have an active streak. Log a Diet Coke to start one!")
        } else if streak == 1 {
            return .result(dialog: "You're on a 1 day streak! Keep it going!")
        } else {
            return .result(dialog: "You're on a \(streak) day streak! Great job!")
        }
    }
}

// MARK: - Show Stats Intent

struct ShowStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show my Diet Coke stats"
    static var description = IntentDescription("View your Diet Coke statistics")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let todayCount = SharedDataManager.getTodayCount()
        let weekCount = SharedDataManager.getThisWeekCount()
        let allTimeCount = SharedDataManager.getEntries().count
        let streak = SharedDataManager.getStreak()

        return .result(dialog: """
            Today: \(todayCount) drinks
            This week: \(weekCount) drinks
            All time: \(allTimeCount) drinks
            Streak: \(streak) days
            """)
    }
}

// MARK: - Log Drink Intent (opens app)

struct LogDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Diet Coke"
    static var description = IntentDescription("Open FridgeCig to log a Diet Coke")

    // Open app so user can properly log with all options
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Size")
    var size: DrinkSizeEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Navigate to add drink screen
        await MainActor.run {
            DeepLinkHandler.shared.shouldNavigateToAddDrink = true
        }

        return .result(dialog: "Opening FridgeCig to add your drink...")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$size)")
    }
}

// MARK: - Open App Intent

struct OpenFridgeCigIntent: AppIntent {
    static var title: LocalizedStringResource = "Open FridgeCig"
    static var description = IntentDescription("Open the FridgeCig app")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Drink Size Entity

struct DrinkSizeEntity: AppEntity {
    var id: String
    var displayName: String
    var ounces: Double

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Drink Size")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    static var defaultQuery = DrinkSizeQuery()

    static let regularCan = DrinkSizeEntity(
        id: "regularCan",
        displayName: "Regular Can (12 oz)",
        ounces: 12
    )
    static let bottle20oz = DrinkSizeEntity(
        id: "bottle20oz",
        displayName: "Bottle (20 oz)",
        ounces: 20
    )
    static let miniCan = DrinkSizeEntity(
        id: "miniCan",
        displayName: "Mini Can (7.5 oz)",
        ounces: 7.5
    )
    static let fountain = DrinkSizeEntity(
        id: "fountain",
        displayName: "Fountain (16 oz)",
        ounces: 16
    )

    static var allCases: [DrinkSizeEntity] = [
        .regularCan,
        .bottle20oz,
        .miniCan,
        .fountain
    ]
}

struct DrinkSizeQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [DrinkSizeEntity] {
        DrinkSizeEntity.allCases.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DrinkSizeEntity] {
        DrinkSizeEntity.allCases
    }

    func defaultResult() async -> DrinkSizeEntity? {
        .regularCan
    }
}

// MARK: - App Shortcuts Provider

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDrinkIntent(),
            phrases: [
                "Log a Diet Coke in \(.applicationName)",
                "Add a Diet Coke in \(.applicationName)",
                "I had a Diet Coke",
                "Log Diet Coke"
            ],
            shortTitle: "Log Diet Coke",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: ShowTodayCountIntent(),
            phrases: [
                "How many Diet Cokes today in \(.applicationName)",
                "Diet Coke count",
                "Today's Diet Cokes"
            ],
            shortTitle: "Today's Count",
            systemImageName: "number.circle.fill"
        )

        AppShortcut(
            intent: ShowStreakIntent(),
            phrases: [
                "Show my streak in \(.applicationName)",
                "Diet Coke streak",
                "My streak"
            ],
            shortTitle: "Show Streak",
            systemImageName: "flame.fill"
        )

        AppShortcut(
            intent: ShowStatsIntent(),
            phrases: [
                "Show my Diet Coke stats",
                "Diet Coke statistics"
            ],
            shortTitle: "Show Stats",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: OpenFridgeCigIntent(),
            phrases: [
                "Open \(.applicationName)"
            ],
            shortTitle: "Open App",
            systemImageName: "cup.and.saucer.fill"
        )
    }
}
