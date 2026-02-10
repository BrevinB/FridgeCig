import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Graph Widget Entry

struct GraphWidgetEntry: TimelineEntry {
    let date: Date
    let last7DaysData: [(date: Date, count: Int, ounces: Double)]
    let totals: (count: Int, ounces: Double)
    let isPremium: Bool
    let configuration: GraphWidgetConfigurationIntent
}

// MARK: - Graph Widget Provider

struct GraphWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = GraphWidgetEntry
    typealias Intent = GraphWidgetConfigurationIntent

    func placeholder(in context: Context) -> GraphWidgetEntry {
        let sampleData: [(date: Date, count: Int, ounces: Double)] = (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
            let count = [2, 3, 1, 4, 2, 3, 5][offset]
            return (date: date, count: count, ounces: Double(count * 12))
        }
        return GraphWidgetEntry(
            date: Date(),
            last7DaysData: sampleData,
            totals: (count: 20, ounces: 240),
            isPremium: true,
            configuration: GraphWidgetConfigurationIntent()
        )
    }

    func snapshot(for configuration: GraphWidgetConfigurationIntent, in context: Context) async -> GraphWidgetEntry {
        let data = SharedDataManager.getLast7DaysData()
        let totals = SharedDataManager.getLast7DaysTotals()
        return GraphWidgetEntry(
            date: Date(),
            last7DaysData: Array(data),
            totals: totals,
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )
    }

    func timeline(for configuration: GraphWidgetConfigurationIntent, in context: Context) async -> Timeline<GraphWidgetEntry> {
        let data = SharedDataManager.getLast7DaysData()
        let totals = SharedDataManager.getLast7DaysTotals()
        let entry = GraphWidgetEntry(
            date: Date(),
            last7DaysData: Array(data),
            totals: totals,
            isPremium: SubscriptionStatusManager.isPremium(),
            configuration: configuration
        )

        // Refresh in 15 minutes or at start of next hour
        let calendar = Calendar.current
        let nextHour = calendar.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let refreshDate = min(nextHour, fifteenMinutes)

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

// MARK: - Graph Widget Views

struct GraphWidgetMediumView: View {
    let entry: GraphWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("7-Day Activity")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(entry.configuration.barColor.color)
            }

            // Chart
            BarChartView(
                data: entry.last7DaysData,
                barColor: entry.configuration.barColor.color,
                displayMode: entry.configuration.displayMode,
                showLabels: true,
                isCompact: false
            )
            .frame(maxHeight: .infinity)

            // Summary
            HStack {
                Text("\(entry.totals.count) drinks")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(entry.totals.ounces)) oz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct GraphWidgetLargeView: View {
    let entry: GraphWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7-Day Activity")
                        .font(.headline)
                    Text(entry.configuration.displayMode == .counts ? "Drink counts" : "Ounces consumed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundStyle(entry.configuration.barColor.color)
            }

            Divider()

            // Chart
            BarChartView(
                data: entry.last7DaysData,
                barColor: entry.configuration.barColor.color,
                displayMode: entry.configuration.displayMode,
                showLabels: true,
                isCompact: false
            )
            .frame(maxHeight: .infinity)

            Divider()

            // Summary stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.totals.count)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(entry.configuration.barColor.color)
                    Text("total drinks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(entry.totals.ounces))")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(entry.configuration.barColor.secondaryColor)
                    Text("total oz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    let average = entry.totals.count > 0 ? Double(entry.totals.count) / 7.0 : 0
                    Text(String(format: "%.1f", average))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("daily avg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

// Premium required views for graph widget
struct GraphPremiumRequiredMediumView: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text("7-Day Graph")
                    .font(.headline)
                Text("Unlock with FridgeCig Pro")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct GraphPremiumRequiredLargeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red.opacity(0.8))
            Text("7-Day Activity Graph")
                .font(.title2.bold())
            Text("Visualize your weekly consumption patterns")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Unlock with FridgeCig Pro")
                .font(.caption)
                .foregroundStyle(.red)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Graph Widget Entry View

struct GraphWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GraphWidgetProvider.Entry

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
        case .systemMedium:
            GraphWidgetMediumView(entry: entry)
        case .systemLarge:
            GraphWidgetLargeView(entry: entry)
        default:
            GraphWidgetMediumView(entry: entry)
        }
    }

    @ViewBuilder
    private var lockedContent: some View {
        switch family {
        case .systemMedium:
            GraphPremiumRequiredMediumView()
        case .systemLarge:
            GraphPremiumRequiredLargeView()
        default:
            GraphPremiumRequiredMediumView()
        }
    }
}

// MARK: - Graph Widget Configuration

struct GraphWidget: Widget {
    let kind: String = "GraphWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GraphWidgetConfigurationIntent.self, provider: GraphWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                GraphWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(entry.isPremium ? URL(string: "fridgecig://stats") : URL(string: "fridgecig://paywall"))
            } else {
                GraphWidgetEntryView(entry: entry)
                    .padding()
                    .background()
                    .widgetURL(entry.isPremium ? URL(string: "fridgecig://stats") : URL(string: "fridgecig://paywall"))
            }
        }
        .configurationDisplayName("7-Day Graph")
        .description("See your DC consumption over the past week.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    GraphWidget()
} timeline: {
    let sampleData: [(date: Date, count: Int, ounces: Double)] = (0..<7).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
        let count = [2, 3, 1, 4, 2, 3, 5][offset]
        return (date: date, count: count, ounces: Double(count * 12))
    }
    GraphWidgetEntry(
        date: .now,
        last7DaysData: sampleData,
        totals: (count: 20, ounces: 240),
        isPremium: true,
        configuration: GraphWidgetConfigurationIntent()
    )
}

#Preview(as: .systemLarge) {
    GraphWidget()
} timeline: {
    let sampleData: [(date: Date, count: Int, ounces: Double)] = (0..<7).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
        let count = [2, 3, 1, 4, 2, 3, 5][offset]
        return (date: date, count: count, ounces: Double(count * 12))
    }
    GraphWidgetEntry(
        date: .now,
        last7DaysData: sampleData,
        totals: (count: 20, ounces: 240),
        isPremium: true,
        configuration: GraphWidgetConfigurationIntent()
    )
}

#Preview("Medium Locked", as: .systemMedium) {
    GraphWidget()
} timeline: {
    GraphWidgetEntry(
        date: .now,
        last7DaysData: [],
        totals: (count: 0, ounces: 0),
        isPremium: false,
        configuration: GraphWidgetConfigurationIntent()
    )
}
