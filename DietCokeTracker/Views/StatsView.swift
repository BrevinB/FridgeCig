import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: DrinkStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview cards
                    OverviewStatsSection()

                    // Weekly chart
                    WeeklyChartSection()

                    // Favorite types
                    FavoriteTypesSection()

                    // Fun stats
                    FunStatsSection()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }
}

struct OverviewStatsSection: View {
    @EnvironmentObject var store: DrinkStore

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Today",
                value: "\(store.todayCount)",
                subtitle: "\(String(format: "%.0f", store.todayOunces)) oz",
                icon: "sun.max.fill",
                iconColor: .orange
            )

            StatCard(
                title: "This Week",
                value: "\(store.thisWeekCount)",
                subtitle: "\(String(format: "%.0f", store.thisWeekOunces)) oz",
                icon: "calendar",
                iconColor: .blue
            )

            StatCard(
                title: "This Month",
                value: "\(store.thisMonthCount)",
                subtitle: "\(String(format: "%.0f", store.thisMonthOunces)) oz",
                icon: "calendar.circle.fill",
                iconColor: .purple
            )

            StatCard(
                title: "All Time",
                value: "\(store.allTimeCount)",
                subtitle: "\(String(format: "%.0f", store.allTimeOunces)) oz",
                icon: "infinity",
                iconColor: .dietCokeRed
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .dietCokeCard()
    }
}

struct WeeklyChartSection: View {
    @EnvironmentObject var store: DrinkStore

    var chartData: [(date: Date, ounces: Double)] {
        store.ouncesLast7Days()
    }

    var maxOunces: Double {
        max(chartData.map { $0.ounces }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(data.ounces > 0 ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.3))
                            .frame(height: max(CGFloat(data.ounces / maxOunces) * 100, 4))

                        Text(dayLabel(for: data.date))
                            .font(.caption2)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)
        }
        .padding(20)
        .dietCokeCard()
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct FavoriteTypesSection: View {
    @EnvironmentObject var store: DrinkStore

    var topTypes: [(type: DrinkType, count: Int)] {
        let counts = store.countByType()
        return counts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { (type: $0.key, count: $0.value) }
    }

    var totalCount: Int {
        topTypes.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Favorite Types")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            if topTypes.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(topTypes, id: \.type) { item in
                        FavoriteTypeRow(
                            type: item.type,
                            count: item.count,
                            percentage: totalCount > 0 ? Double(item.count) / Double(totalCount) : 0
                        )
                    }
                }
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

struct FavoriteTypeRow: View {
    let type: DrinkType
    let count: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(.dietCokeRed)
                    .frame(width: 24)

                Text(type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.dietCokeSilver.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.dietCokeRed)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct FunStatsSection: View {
    @EnvironmentObject var store: DrinkStore

    var caffeineToday: Double {
        // Diet Coke has ~46mg caffeine per 12oz
        (store.todayOunces / 12) * 46
    }

    var totalCaffeine: Double {
        (store.allTimeOunces / 12) * 46
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fun Facts")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            VStack(spacing: 12) {
                FunStatRow(
                    icon: "bolt.fill",
                    iconColor: .yellow,
                    title: "Caffeine Today",
                    value: "\(String(format: "%.0f", caffeineToday)) mg"
                )

                FunStatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Current Streak",
                    value: "\(store.streakDays) days"
                )

                FunStatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    title: "Daily Average",
                    value: String(format: "%.1f drinks", store.averagePerDay)
                )

                if let favorite = store.mostPopularType {
                    FunStatRow(
                        icon: "heart.fill",
                        iconColor: .dietCokeRed,
                        title: "Favorite",
                        value: favorite.displayName
                    )
                }
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

struct FunStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DrinkStore())
}
