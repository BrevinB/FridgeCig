import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var recapService: WeeklyRecapService
    @State private var showingWeeklyRecap = false
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card
                    StatsHeroCard()

                    // Weekly Recap Button
                    WeeklyRecapButton(showingRecap: $showingWeeklyRecap)

                    // Weekly chart
                    WeeklyChartSection()

                    // Favorite types
                    FavoriteTypesSection()

                    // Fun stats
                    FunStatsSection()
                }
                .padding()
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Statistics")
            .sheet(isPresented: $showingWeeklyRecap) {
                WeeklyRecapSheet()
            }
        }
    }
}

// MARK: - Weekly Recap Button

struct WeeklyRecapButton: View {
    @Binding var showingRecap: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            showingRecap = true
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.dietCokeRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Recap")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    Text("See how your week stacked up")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.dietCokeRed.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.dietCokeRed.opacity(colorScheme == .dark ? 0.15 : 0.1),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Hero Card

struct StatsHeroCard: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background with metallic gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)

            // Subtle fizz bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            // Content
            VStack(spacing: 16) {
                Text("All Time Stats")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeDarkSilver)

                // Big number
                Text("\(store.allTimeCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Diet Cokes Logged")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                // Stats row
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(String(format: "%.0f", store.allTimeOunces))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dietCokeCharcoal)
                        Text("Total oz")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(String(format: "%.0f", store.allTimeOunces)) total ounces")

                    Rectangle()
                        .fill(Color.dietCokeSilver.opacity(0.3))
                        .frame(width: 1, height: 40)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("\(store.streakDays)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dietCokeCharcoal)
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(store.streakDays) day streak")

                    Rectangle()
                        .fill(Color.dietCokeSilver.opacity(0.3))
                        .frame(width: 1, height: 40)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", store.averagePerDay))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dietCokeCharcoal)
                        Text("Daily Avg")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(String(format: "%.1f", store.averagePerDay)) daily average")
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("All time stats: \(store.allTimeCount) Diet Cokes logged, \(String(format: "%.0f", store.allTimeOunces)) total ounces, \(store.streakDays) day streak, \(String(format: "%.1f", store.averagePerDay)) daily average")
        .frame(height: 280)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 12,
            y: 6
        )
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.dietCokeCharcoal)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeDarkSilver)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.dietCokeSilver)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            y: 3
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

struct WeeklyChartSection: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

    var chartData: [(date: Date, ounces: Double)] {
        store.ouncesLast7Days()
    }

    var maxOunces: Double {
        max(chartData.map { $0.ounces }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Last 7 Days")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Text("\(String(format: "%.0f", chartData.map { $0.ounces }.reduce(0, +))) oz total")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeRed)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                data.ounces > 0
                                    ? LinearGradient(
                                        colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [Color.dietCokeSilver.opacity(0.3), Color.dietCokeSilver.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .frame(height: max(CGFloat(data.ounces / maxOunces) * 100, 4))

                        Text(dayLabel(for: data.date))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Calendar.current.isDateInToday(data.date) ? .dietCokeRed : .dietCokeDarkSilver)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(dayLabel(for: data.date)): \(String(format: "%.0f", data.ounces)) ounces\(Calendar.current.isDateInToday(data.date) ? ", today" : "")")
                }
            }
            .frame(height: 130)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            y: 3
        )
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct FavoriteTypesSection: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

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
            HStack {
                Text("Favorite Types")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if let top = topTypes.first {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(top.type.shortName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
            }

            if topTypes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title)
                        .foregroundColor(.dietCokeSilver)
                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                }
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            y: 3
        )
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
                    .accessibilityHidden(true)

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
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.displayName): \(count) drinks, \(Int(percentage * 100)) percent")
    }
}

struct FunStatsSection: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

    var caffeineToday: Double {
        // DC has ~46mg caffeine per 12oz
        (store.todayOunces / 12) * 46
    }

    var totalCaffeine: Double {
        (store.allTimeOunces / 12) * 46
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fun Facts")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.dietCokeRed)
            }

            VStack(spacing: 14) {
                FunStatRow(
                    icon: "bolt.fill",
                    iconColor: .yellow,
                    title: "Caffeine Today",
                    value: "\(String(format: "%.0f", caffeineToday)) mg"
                )

                Divider()
                    .background(Color.dietCokeSilver.opacity(0.3))
                    .accessibilityHidden(true)

                FunStatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Current Streak",
                    value: "\(store.streakDays) days"
                )

                Divider()
                    .background(Color.dietCokeSilver.opacity(0.3))
                    .accessibilityHidden(true)

                FunStatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    title: "Daily Average",
                    value: String(format: "%.1f drinks", store.averagePerDay)
                )

                if let favorite = store.mostPopularType {
                    Divider()
                        .background(Color.dietCokeSilver.opacity(0.3))
                        .accessibilityHidden(true)

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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            y: 3
        )
    }
}

struct FunStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    StatsView()
        .environmentObject(DrinkStore())
        .environmentObject(WeeklyRecapService())
}
