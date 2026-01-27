import SwiftUI
import WidgetKit

/// A reusable bar chart view for displaying 7-day activity data
struct BarChartView: View {
    let data: [(date: Date, count: Int, ounces: Double)]
    let barColor: Color
    let displayMode: GraphDisplayMode
    let showLabels: Bool
    let isCompact: Bool

    init(
        data: [(date: Date, count: Int, ounces: Double)],
        barColor: Color = .red,
        displayMode: GraphDisplayMode = .counts,
        showLabels: Bool = true,
        isCompact: Bool = false
    ) {
        self.data = data
        self.barColor = barColor
        self.displayMode = displayMode
        self.showLabels = showLabels
        self.isCompact = isCompact
    }

    private var maxValue: Double {
        let values = data.map { displayMode == .counts ? Double($0.count) : $0.ounces }
        return values.max() ?? 1.0
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: isCompact ? 4 : 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                VStack(spacing: isCompact ? 2 : 4) {
                    // Bar
                    BarView(
                        value: displayMode == .counts ? Double(dayData.count) : dayData.ounces,
                        maxValue: maxValue,
                        color: barColor,
                        isToday: Calendar.current.isDateInToday(dayData.date)
                    )

                    // Day label
                    if showLabels {
                        Text(shortDayName(for: dayData.date))
                            .font(.system(size: isCompact ? 8 : 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Calendar.current.isDateInToday(dayData.date) ? barColor : .secondary)
                    }
                }
            }
        }
    }

    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let name = formatter.string(from: date)
        return String(name.prefix(1))
    }
}

/// Individual bar in the chart
struct BarView: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let isToday: Bool

    private var normalizedHeight: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: 3)
                    .fill(isToday ? color : color.opacity(0.6))
                    .frame(height: max(4, geometry.size.height * normalizedHeight))

                if value == 0 {
                    // Show a small indicator for zero days
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

/// Summary view showing totals for the 7-day period
struct ChartSummaryView: View {
    let totals: (count: Int, ounces: Double)
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(totals.count)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(accentColor)
                Text("drinks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(totals.ounces))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(accentColor.opacity(0.8))
                Text("oz")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Bar Chart") {
    let sampleData: [(date: Date, count: Int, ounces: Double)] = (0..<7).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
        let count = [2, 3, 1, 4, 2, 3, 5][offset]
        return (date: date, count: count, ounces: Double(count * 12))
    }

    return BarChartView(data: sampleData)
        .frame(height: 80)
        .padding()
}
