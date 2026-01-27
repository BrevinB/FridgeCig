import WidgetKit
import SwiftUI

// MARK: - Minimal Lock Screen Widget
// Uses the shared DietCokeProvider and displays minimal/clean lock screen widgets

// MARK: - Lock Screen Views

/// Minimal circular widget - just the count number with subtle cup icon
struct MinimalAccessoryCircularView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 0) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .widgetAccentable()

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Image(systemName: "crown.fill")
                .font(.title2)
        }
    }
}

/// Minimal rectangular widget - count and ounces side by side
struct MinimalAccessoryRectangularView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            HStack(spacing: 16) {
                // Count
                VStack(alignment: .center, spacing: 0) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .widgetAccentable()
                    Text("DCs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 30)

                // Ounces
                VStack(alignment: .center, spacing: 0) {
                    Text("\(Int(entry.todayOunces))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("oz")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
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
}

/// Minimal inline widget - just count with cup icon
struct MinimalAccessoryInlineView: View {
    let entry: DietCokeEntry

    var body: some View {
        if entry.isPremium {
            Label("\(entry.todayCount) DCs • \(Int(entry.todayOunces)) oz", systemImage: "cup.and.saucer.fill")
        } else {
            Label("FridgeCig Pro", systemImage: "crown.fill")
        }
    }
}

// MARK: - Minimal Lock Screen Widget Entry View

struct MinimalLockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DietCokeProvider.Entry

    var body: some View {
        switch family {
        case .accessoryCircular:
            MinimalAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            MinimalAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            MinimalAccessoryInlineView(entry: entry)
        default:
            MinimalAccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Minimal Lock Screen Widget Configuration

struct MinimalLockScreenWidget: Widget {
    let kind: String = "MinimalLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DietCokeProvider()) { entry in
            if #available(iOS 17.0, *) {
                MinimalLockScreenWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MinimalLockScreenWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Minimal Count")
        .description("Clean, minimal display of your daily DC count.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    MinimalLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 5, todayOunces: 60, streak: 42, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryRectangular) {
    MinimalLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 5, todayOunces: 60, streak: 42, weekCount: 15, isPremium: true)
}

#Preview(as: .accessoryInline) {
    MinimalLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 5, todayOunces: 60, streak: 42, weekCount: 15, isPremium: true)
}

#Preview("Locked Circular", as: .accessoryCircular) {
    MinimalLockScreenWidget()
} timeline: {
    DietCokeEntry(date: .now, todayCount: 0, todayOunces: 0, streak: 0, weekCount: 0, isPremium: false)
}
