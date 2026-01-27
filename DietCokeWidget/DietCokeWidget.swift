import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct DietCokeEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let todayOunces: Double
    let streak: Int
    let weekCount: Int
    let isPremium: Bool
}

// MARK: - Timeline Provider

struct DietCokeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DietCokeEntry {
        DietCokeEntry(date: Date(), todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (DietCokeEntry) -> ()) {
        let entry = DietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount(),
            isPremium: SubscriptionStatusManager.isPremium()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DietCokeEntry>) -> ()) {
        let entry = DietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount(),
            isPremium: SubscriptionStatusManager.isPremium()
        )

        // Refresh at the start of next hour or in 15 minutes, whichever is sooner
        let calendar = Calendar.current
        let nextHour = calendar.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let refreshDate = min(nextHour, fifteenMinutes)

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Widget Views

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let entry: DietCokeEntry

    var body: some View {
        Gauge(value: Double(min(entry.todayCount, 10)), in: 0...10) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text("\(entry.todayCount)")
                .font(.system(.title2, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularView: View {
    let entry: DietCokeEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.todayCount) DCs")
                    .font(.headline)
                    .widgetAccentable()
                Text("\(Int(entry.todayOunces)) oz • \(entry.streak) day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: DietCokeEntry

    var body: some View {
        Label("\(entry.todayCount) DCs today", systemImage: "cup.and.saucer.fill")
    }
}

// MARK: - Home Screen Widgets

struct SmallWidgetView: View {
    let entry: DietCokeEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                Spacer()
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.todayCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.red)

            Text("\(Int(entry.todayOunces)) oz")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: DietCokeEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Today's count
            VStack(spacing: 4) {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("\(entry.todayCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)

                Text("\(Int(entry.todayOunces)) oz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right side - Stats
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.streak) day streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("\(entry.weekCount) this week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: DietCokeEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.red)
                Text("DC Tracker")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Main stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(Int(entry.todayOunces))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.red.opacity(0.7))
                    Text("Ounces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(entry.streak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Bottom stats
            HStack {
                Label("\(entry.weekCount) this week", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tap to log")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

// MARK: - Premium Required Views

struct PremiumRequiredSmallView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.title)
                .foregroundStyle(.red)

            Text("FridgeCig Pro")
                .font(.caption.bold())

            Text("Tap to upgrade")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct PremiumRequiredMediumView: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("FridgeCig Pro")
                    .font(.headline)
                Text("Unlock widgets with a subscription")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Tap to upgrade")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

struct PremiumRequiredLargeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("FridgeCig Pro")
                .font(.title2.bold())

            Text("Unlock widgets to track your Diet Cokes at a glance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Tap to upgrade")
                .font(.caption)
                .foregroundStyle(.red)

            Spacer()
        }
        .padding()
    }
}

struct PremiumRequiredAccessoryView: View {
    var body: some View {
        Image(systemName: "crown.fill")
    }
}

// MARK: - Main Widget Entry View

struct DietCokeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DietCokeProvider.Entry

    var body: some View {
        if entry.isPremium {
            premiumContent
        } else {
            lockedContent
        }
    }

    @ViewBuilder
    private var premiumContent: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }

    @ViewBuilder
    private var lockedContent: some View {
        switch family {
        case .systemSmall:
            PremiumRequiredSmallView()
        case .systemMedium:
            PremiumRequiredMediumView()
        case .systemLarge:
            PremiumRequiredLargeView()
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            PremiumRequiredAccessoryView()
        default:
            PremiumRequiredSmallView()
        }
    }
}

// MARK: - Widget Configuration

struct DietCokeWidget: Widget {
    let kind: String = "DietCokeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DietCokeProvider()) { entry in
            if #available(iOS 17.0, *) {
                DietCokeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DietCokeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("DC Tracker")
        .description("Track your daily DC consumption.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

#Preview(as: .systemMedium) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

#Preview(as: .systemLarge) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryCircular) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryRectangular) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryInline) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: true)
}

// Preview locked state
#Preview("Small Locked", as: .systemSmall) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: false)
}

#Preview("Medium Locked", as: .systemMedium) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15, isPremium: false)
}

// MARK: - Configurable Widget Entry

struct ConfigurableDietCokeEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let todayOunces: Double
    let streak: Int
    let weekCount: Int
    let isPremium: Bool
    let configuration: ConfigurableWidgetIntent
}

// MARK: - Configurable Widget Provider

struct ConfigurableDietCokeProvider: AppIntentTimelineProvider {
    typealias Entry = ConfigurableDietCokeEntry
    typealias Intent = ConfigurableWidgetIntent

    func placeholder(in context: Context) -> ConfigurableDietCokeEntry {
        ConfigurableDietCokeEntry(
            date: Date(),
            todayCount: 3,
            todayOunces: 36,
            streak: 5,
            weekCount: 15,
            isPremium: true,
            configuration: ConfigurableWidgetIntent()
        )
    }

    func snapshot(for configuration: ConfigurableWidgetIntent, in context: Context) async -> ConfigurableDietCokeEntry {
        ConfigurableDietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount(),
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurableWidgetIntent, in context: Context) async -> Timeline<ConfigurableDietCokeEntry> {
        let entry = ConfigurableDietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount(),
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )

        let calendar = Calendar.current
        let nextHour = calendar.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let refreshDate = min(nextHour, fifteenMinutes)

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

// MARK: - Configurable Widget Views

struct ConfigurableSmallWidgetView: View {
    let entry: ConfigurableDietCokeEntry

    var body: some View {
        let config = entry.configuration

        VStack(spacing: 8) {
            HStack {
                Image(systemName: config.primaryStat.icon)
                    .font(.caption)
                    .foregroundStyle(config.accentColor.color.opacity(0.8))
                Spacer()
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(config.primaryStat.getValue(from: toDietCokeEntry(entry)))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(config.accentColor.color)

            Text(config.primaryStat.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let secondaryValue = config.secondaryStat.getValue(from: toDietCokeEntry(entry)) {
                Text(secondaryValue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
    }
}

struct ConfigurableMediumWidgetView: View {
    let entry: ConfigurableDietCokeEntry

    var body: some View {
        let config = entry.configuration
        let dietCokeEntry = toDietCokeEntry(entry)

        HStack(spacing: 16) {
            // Left side - Primary stat
            VStack(spacing: 4) {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(config.primaryStat.getValue(from: dietCokeEntry))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(config.accentColor.color)

                Text(config.primaryStat.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right side - Other stats
            VStack(alignment: .leading, spacing: 12) {
                if config.primaryStat != .streak {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(entry.streak) day streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                if config.primaryStat != .count {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundStyle(config.accentColor.color)
                        Text("\(entry.todayCount) today")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("\(entry.weekCount) this week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

struct ConfigurableLargeWidgetView: View {
    let entry: ConfigurableDietCokeEntry

    var body: some View {
        let config = entry.configuration

        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(config.accentColor.color)
                Text("DC Tracker")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Main stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(config.accentColor.color)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(Int(entry.todayOunces))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(config.accentColor.secondaryColor)
                    Text("Ounces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(entry.streak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Bottom stats
            HStack {
                Label("\(entry.weekCount) this week", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tap to log")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

// MARK: - Configurable Widget Entry View

struct ConfigurableDietCokeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ConfigurableDietCokeProvider.Entry

    var body: some View {
        if entry.isPremium {
            premiumContent
        } else {
            lockedContent
        }
    }

    @ViewBuilder
    private var premiumContent: some View {
        switch family {
        case .systemSmall:
            ConfigurableSmallWidgetView(entry: entry)
        case .systemMedium:
            ConfigurableMediumWidgetView(entry: entry)
        case .systemLarge:
            ConfigurableLargeWidgetView(entry: entry)
        default:
            ConfigurableSmallWidgetView(entry: entry)
        }
    }

    @ViewBuilder
    private var lockedContent: some View {
        switch family {
        case .systemSmall:
            PremiumRequiredSmallView()
        case .systemMedium:
            PremiumRequiredMediumView()
        case .systemLarge:
            PremiumRequiredLargeView()
        default:
            PremiumRequiredSmallView()
        }
    }
}

// MARK: - Configurable Widget Configuration

struct ConfigurableDietCokeWidget: Widget {
    let kind: String = "ConfigurableDietCokeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurableWidgetIntent.self, provider: ConfigurableDietCokeProvider()) { entry in
            if #available(iOS 17.0, *) {
                ConfigurableDietCokeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ConfigurableDietCokeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Customizable Tracker")
        .description("Customize which stats to display.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

// MARK: - Helper

/// Convert ConfigurableDietCokeEntry to DietCokeEntry for stat calculations
private func toDietCokeEntry(_ entry: ConfigurableDietCokeEntry) -> DietCokeEntry {
    DietCokeEntry(
        date: entry.date,
        todayCount: entry.todayCount,
        todayOunces: entry.todayOunces,
        streak: entry.streak,
        weekCount: entry.weekCount,
        isPremium: entry.isPremium
    )
}

// MARK: - Configurable Widget Previews

#Preview("Configurable Small", as: .systemSmall) {
    ConfigurableDietCokeWidget()
} timeline: {
    ConfigurableDietCokeEntry(
        date: .now,
        todayCount: 3,
        todayOunces: 36,
        streak: 5,
        weekCount: 15,
        isPremium: true,
        configuration: ConfigurableWidgetIntent()
    )
}

#Preview("Configurable Medium", as: .systemMedium) {
    ConfigurableDietCokeWidget()
} timeline: {
    ConfigurableDietCokeEntry(
        date: .now,
        todayCount: 3,
        todayOunces: 36,
        streak: 5,
        weekCount: 15,
        isPremium: true,
        configuration: ConfigurableWidgetIntent()
    )
}
