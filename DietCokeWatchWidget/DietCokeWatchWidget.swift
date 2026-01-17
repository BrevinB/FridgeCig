import WidgetKit
import SwiftUI

// MARK: - Complication Entry

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let todayOunces: Double
    let streak: Int
    let isPremium: Bool
}

// MARK: - Complication Provider

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), todayCount: 3, todayOunces: 36, streak: 5, isPremium: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> ()) {
        let entry = ComplicationEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            isPremium: SubscriptionStatusManager.isPremium()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> ()) {
        let entry = ComplicationEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            isPremium: SubscriptionStatusManager.isPremium()
        )

        let refreshDate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct ComplicationCircularView: View {
    let entry: ComplicationEntry

    var body: some View {
        Gauge(value: Double(min(entry.todayCount, 10)), in: 0...10) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text("\(entry.todayCount)")
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.red)
    }
}

struct ComplicationRectangularView: View {
    let entry: ComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title3)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.todayCount) DCs")
                    .font(.headline)
                    .widgetAccentable()
                HStack(spacing: 8) {
                    Text("\(Int(entry.todayOunces)) oz")
                    if entry.streak > 1 {
                        Label("\(entry.streak)d", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct ComplicationCornerView: View {
    let entry: ComplicationEntry

    var body: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.title3)
            .foregroundStyle(.red)
            .widgetLabel {
                Text("\(entry.todayCount) DCs")
            }
    }
}

struct ComplicationInlineView: View {
    let entry: ComplicationEntry

    var body: some View {
        Label("\(entry.todayCount) DCs", systemImage: "cup.and.saucer.fill")
    }
}

// MARK: - Locked Views (Non-Premium)

struct LockedCircularView: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .font(.title2)
            .foregroundStyle(.red)
    }
}

struct LockedRectangularView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.title3)
                .foregroundStyle(.red)

            VStack(alignment: .leading) {
                Text("FridgeCig Pro")
                    .font(.caption)
                Text("Upgrade to unlock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Complication Entry View

struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ComplicationProvider.Entry

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
        case .accessoryCircular:
            ComplicationCircularView(entry: entry)
        case .accessoryRectangular:
            ComplicationRectangularView(entry: entry)
        case .accessoryCorner:
            ComplicationCornerView(entry: entry)
        case .accessoryInline:
            ComplicationInlineView(entry: entry)
        default:
            ComplicationCircularView(entry: entry)
        }
    }

    @ViewBuilder
    private var lockedContent: some View {
        switch family {
        case .accessoryCircular, .accessoryCorner:
            LockedCircularView()
        case .accessoryRectangular:
            LockedRectangularView()
        case .accessoryInline:
            Label("Upgrade to Pro", systemImage: "crown.fill")
        default:
            LockedCircularView()
        }
    }
}

// MARK: - Complication Widget

struct DietCokeWatchWidget: Widget {
    let kind: String = "DietCokeWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("DC")
        .description("Track your daily DC count.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    DietCokeWatchWidget()
} timeline: {
    ComplicationEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, isPremium: true)
}

#Preview(as: .accessoryRectangular) {
    DietCokeWatchWidget()
} timeline: {
    ComplicationEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, isPremium: true)
}

#Preview(as: .accessoryCorner) {
    DietCokeWatchWidget()
} timeline: {
    ComplicationEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, isPremium: true)
}

#Preview("Circular Locked", as: .accessoryCircular) {
    DietCokeWatchWidget()
} timeline: {
    ComplicationEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, isPremium: false)
}

#Preview("Rectangular Locked", as: .accessoryRectangular) {
    DietCokeWatchWidget()
} timeline: {
    ComplicationEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, isPremium: false)
}
