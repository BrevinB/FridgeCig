import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DietCokeEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let todayOunces: Double
    let streak: Int
    let weekCount: Int
}

// MARK: - Timeline Provider

struct DietCokeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DietCokeEntry {
        DietCokeEntry(date: Date(), todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
    }

    func getSnapshot(in context: Context, completion: @escaping (DietCokeEntry) -> ()) {
        let entry = DietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DietCokeEntry>) -> ()) {
        let entry = DietCokeEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount(),
            todayOunces: SharedDataManager.getTodayOunces(),
            streak: SharedDataManager.getStreak(),
            weekCount: SharedDataManager.getThisWeekCount()
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
                Text("\(entry.todayCount) Diet Cokes")
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
        Label("\(entry.todayCount) Diet Cokes today", systemImage: "cup.and.saucer.fill")
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
                Text("Diet Coke Tracker")
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

// MARK: - Main Widget Entry View

struct DietCokeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DietCokeProvider.Entry

    var body: some View {
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
        .configurationDisplayName("Diet Coke Tracker")
        .description("Track your daily Diet Coke consumption.")
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
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}

#Preview(as: .systemMedium) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}

#Preview(as: .systemLarge) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}

#Preview(as: .accessoryCircular) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}

#Preview(as: .accessoryRectangular) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}

#Preview(as: .accessoryInline) {
    DietCokeWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 3, todayOunces: 36, streak: 5, weekCount: 15)
}
