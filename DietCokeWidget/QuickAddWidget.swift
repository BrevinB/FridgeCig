import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Quick Add Widget

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            if #available(iOS 17.0, *) {
                QuickAddWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                QuickAddWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Quick Add")
        .description("Quickly log a DC without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Provider

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date(), todayCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> ()) {
        let entry = QuickAddEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> ()) {
        let entry = QuickAddEntry(
            date: Date(),
            todayCount: SharedDataManager.getTodayCount()
        )

        let refreshDate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct QuickAddEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
}

// MARK: - Widget Views

struct QuickAddWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: QuickAddEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuickAddView(entry: entry)
        case .systemMedium:
            MediumQuickAddView(entry: entry)
        default:
            SmallQuickAddView(entry: entry)
        }
    }
}

struct SmallQuickAddView: View {
    let entry: QuickAddEntry

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 12) {
                HStack {
                    Text("\(entry.todayCount) today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                Button(intent: QuickAddDrinkIntent()) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                        Text("Add Can")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        } else {
            // Fallback for older iOS - just show count
            VStack {
                Text("\(entry.todayCount)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("today")
                    .font(.caption)
            }
        }
    }
}

struct MediumQuickAddView: View {
    let entry: QuickAddEntry

    var body: some View {
        if #available(iOS 17.0, *) {
            HStack(spacing: 16) {
                // Left side - count
                VStack(spacing: 4) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                    Text("today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right side - quick add buttons
                VStack(spacing: 8) {
                    Button(intent: QuickAddDrinkIntent()) {
                        HStack {
                            Image(systemName: "cylinder.fill")
                            Text("Regular Can")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.red, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(intent: QuickAddBottleIntent()) {
                        HStack {
                            Image(systemName: "flask.fill")
                            Text("20oz Bottle")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        } else {
            // Fallback
            HStack {
                Text("\(entry.todayCount) today")
                    .font(.title)
                Spacer()
                Text("Tap to open")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    QuickAddWidget()
} timeline: {
    QuickAddEntry(date: .now, todayCount: 3)
}

#Preview(as: .systemMedium) {
    QuickAddWidget()
} timeline: {
    QuickAddEntry(date: .now, todayCount: 3)
}
