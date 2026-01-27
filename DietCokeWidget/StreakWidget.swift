import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Streak Widget Entry

struct StreakWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let milestoneInfo: (current: Int, next: Int, progress: Double)
    let encouragement: String
    let isOnMilestone: Bool
    let isPremium: Bool
    let configuration: StreakWidgetConfigurationIntent
}

// MARK: - Streak Widget Provider

struct StreakWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = StreakWidgetEntry
    typealias Intent = StreakWidgetConfigurationIntent

    func placeholder(in context: Context) -> StreakWidgetEntry {
        StreakWidgetEntry(
            date: Date(),
            streak: 42,
            milestoneInfo: (current: 42, next: 60, progress: 0.67),
            encouragement: "Keep it up!",
            isOnMilestone: false,
            isPremium: true,
            configuration: StreakWidgetConfigurationIntent()
        )
    }

    func snapshot(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> StreakWidgetEntry {
        let streak = SharedDataManager.getStreak()
        let milestoneInfo = SharedDataManager.getStreakMilestoneInfo()
        let encouragement = SharedDataManager.getStreakEncouragement()
        let isOnMilestone = SharedDataManager.isOnMilestone()

        return StreakWidgetEntry(
            date: Date(),
            streak: streak,
            milestoneInfo: milestoneInfo,
            encouragement: encouragement,
            isOnMilestone: isOnMilestone,
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )
    }

    func timeline(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> Timeline<StreakWidgetEntry> {
        let streak = SharedDataManager.getStreak()
        let milestoneInfo = SharedDataManager.getStreakMilestoneInfo()
        let encouragement = SharedDataManager.getStreakEncouragement()
        let isOnMilestone = SharedDataManager.isOnMilestone()

        let entry = StreakWidgetEntry(
            date: Date(),
            streak: streak,
            milestoneInfo: milestoneInfo,
            encouragement: encouragement,
            isOnMilestone: isOnMilestone,
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )

        // Refresh in 15 minutes or at midnight (streak changes at midnight)
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let refreshDate = min(midnight, fifteenMinutes)

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

// MARK: - Streak Widget Views

struct StreakWidgetSmallView: View {
    let entry: StreakWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Flame badge
            StreakBadgeView(
                streak: entry.streak,
                flameColor: entry.configuration.flameColor,
                size: .medium
            )

            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct StreakWidgetMediumView: View {
    let entry: StreakWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - streak display
            VStack(spacing: 4) {
                FlameRowView(
                    streak: entry.streak,
                    flameColor: entry.configuration.flameColor,
                    maxFlames: 5
                )

                Text("\(entry.streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.configuration.flameColor.color)

                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if entry.configuration.showMilestoneProgress {
                Divider()

                // Right side - milestone progress
                VStack(alignment: .leading, spacing: 12) {
                    MilestoneProgressView(
                        current: entry.milestoneInfo.current,
                        next: entry.milestoneInfo.next,
                        progress: entry.milestoneInfo.progress,
                        accentColor: entry.configuration.flameColor.color
                    )
                    .frame(maxWidth: .infinity)

                    Text("Next milestone: \(entry.milestoneInfo.next)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.encouragement)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

// Premium required views for streak widget
struct StreakPremiumRequiredSmallView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange.opacity(0.8))

            Text("Streak")
                .font(.caption.bold())

            Text("Unlock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct StreakPremiumRequiredMediumView: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Streak Tracker")
                    .font(.headline)
                Text("Track your daily streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Unlock with FridgeCig Pro")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

// MARK: - Streak Widget Entry View

struct StreakWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: StreakWidgetProvider.Entry

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
            StreakWidgetSmallView(entry: entry)
        case .systemMedium:
            StreakWidgetMediumView(entry: entry)
        default:
            StreakWidgetSmallView(entry: entry)
        }
    }

    @ViewBuilder
    private var lockedContent: some View {
        switch family {
        case .systemSmall:
            StreakPremiumRequiredSmallView()
        case .systemMedium:
            StreakPremiumRequiredMediumView()
        default:
            StreakPremiumRequiredSmallView()
        }
    }
}

// MARK: - Streak Widget Configuration

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StreakWidgetConfigurationIntent.self, provider: StreakWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                StreakWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Streak Tracker")
        .description("Track your daily DC streak with milestone progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: .now,
        streak: 42,
        milestoneInfo: (current: 42, next: 60, progress: 0.67),
        encouragement: "Keep it up!",
        isOnMilestone: false,
        isPremium: true,
        configuration: StreakWidgetConfigurationIntent()
    )
}

#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: .now,
        streak: 42,
        milestoneInfo: (current: 42, next: 60, progress: 0.67),
        encouragement: "Keep it up!",
        isOnMilestone: false,
        isPremium: true,
        configuration: StreakWidgetConfigurationIntent()
    )
}

#Preview("Small Locked", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: .now,
        streak: 0,
        milestoneInfo: (current: 0, next: 7, progress: 0),
        encouragement: "",
        isOnMilestone: false,
        isPremium: false,
        configuration: StreakWidgetConfigurationIntent()
    )
}
