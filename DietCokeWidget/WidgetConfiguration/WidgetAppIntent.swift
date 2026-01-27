import AppIntents
import WidgetKit

// MARK: - Graph Widget Configuration Intent

struct GraphWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Graph Widget"
    static var description = IntentDescription("Configure how the graph widget displays data.")

    @Parameter(title: "Bar Color", default: .dietCokeRed)
    var barColor: WidgetAccentColor

    @Parameter(title: "Display Mode", default: .counts)
    var displayMode: GraphDisplayMode

    init() {}

    init(barColor: WidgetAccentColor, displayMode: GraphDisplayMode) {
        self.barColor = barColor
        self.displayMode = displayMode
    }
}

// MARK: - Streak Widget Configuration Intent

struct StreakWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Streak Widget"
    static var description = IntentDescription("Configure how the streak widget displays.")

    @Parameter(title: "Flame Color", default: .orange)
    var flameColor: WidgetFlameColor

    @Parameter(title: "Show Milestone Progress", default: true)
    var showMilestoneProgress: Bool

    init() {}

    init(flameColor: WidgetFlameColor, showMilestoneProgress: Bool) {
        self.flameColor = flameColor
        self.showMilestoneProgress = showMilestoneProgress
    }
}

// MARK: - Configurable Main Widget Intent

struct ConfigurableWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure DC Tracker Widget"
    static var description = IntentDescription("Configure what stats to display in the widget.")

    @Parameter(title: "Accent Color", default: .dietCokeRed)
    var accentColor: WidgetAccentColor

    @Parameter(title: "Primary Stat", default: .count)
    var primaryStat: WidgetPrimaryStat

    @Parameter(title: "Secondary Stat", default: .ounces)
    var secondaryStat: WidgetSecondaryStat

    init() {}

    init(accentColor: WidgetAccentColor, primaryStat: WidgetPrimaryStat, secondaryStat: WidgetSecondaryStat) {
        self.accentColor = accentColor
        self.primaryStat = primaryStat
        self.secondaryStat = secondaryStat
    }
}
