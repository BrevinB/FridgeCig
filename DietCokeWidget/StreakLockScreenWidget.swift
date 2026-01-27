import WidgetKit
import SwiftUI

// MARK: - Streak Lock Screen Widget
// Uses the shared DietCokeProvider and displays streak-focused lock screen widgets

// MARK: - Lock Screen Views

/// Circular lock screen widget showing streak with flame in gauge style
struct StreakAccessoryCircularView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            Gauge(value: Double(min(entry.streak, 100)), in: 0...100) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(entry.streak)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
        } else {
            Image(systemName: "crown.fill")
                .font(.title2)
        }
    }
}

/// Rectangular lock screen widget showing streak with encouragement
struct StreakAccessoryRectangularView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.streak) day streak")
                        .font(.headline)
                        .widgetAccentable()

                    Text(encouragementText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("FridgeCig Pro")
                        .font(.headline)
                    Text("Unlock widgets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var encouragementText: String {
        let info = SharedDataManager.getStreakMilestoneInfo()
        let daysToGo = info.next - info.current
        if daysToGo <= 1 {
            return "Almost at \(info.next)!"
        } else if daysToGo <= 3 {
            return "\(daysToGo) days to \(info.next)!"
        } else {
            return "Keep going!"
        }
    }
}

/// Inline lock screen widget showing streak
struct StreakAccessoryInlineView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            Label("\(entry.streak) day streak", systemImage: "flame.fill")
        } else {
            Label("FridgeCig Pro", systemImage: "crown.fill")
        }
    }
}

// MARK: - Streak Lock Screen Widget Entry View

struct StreakLockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DietCokeProvider.Entry

    var body: some View {
        switch family {
        case .accessoryCircular:
            StreakAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            StreakAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            StreakAccessoryInlineView(entry: entry)
        default:
            StreakAccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Streak Lock Screen Widget Configuration

struct StreakLockScreenWidget: Widget {
    let kind: String = "StreakLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DietCokeProvider()) { entry in
            if #available(iOS 17.0, *) {
                StreakLockScreenWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakLockScreenWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Streak")
        .description("Show your DC streak on the lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    StreakLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 42, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryRectangular) {
    StreakLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 42, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryInline) {
    StreakLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 42, weekCount: 15, isPremium: true)
}

#Preview("Locked Circular", as: .accessoryCircular) {
    StreakLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 0, todayOunces: 0, streak: 0, weekCount: 0, isPremium: false)
}
