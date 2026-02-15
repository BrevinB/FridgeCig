import SwiftUI

struct WeeklyRecapView: View {
    let recap: WeeklyRecap
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showingSharePreview = false
    @State private var showingPaywall = false
    @State private var weekPhotos: [UIImage] = []

    /// Get photos from entries within the recap's date range
    private func loadWeekPhotos() -> [UIImage] {
        let calendar = Calendar.current
        // Use the calendar week interval for accurate filtering that includes the full last day
        let weekEnd: Date
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: recap.weekStartDate) {
            weekEnd = weekInterval.end
        } else {
            weekEnd = calendar.date(byAdding: .day, value: 7, to: recap.weekStartDate) ?? recap.weekEndDate
        }

        let weekEntries = store.entries.filter { entry in
            entry.timestamp >= recap.weekStartDate && entry.timestamp < weekEnd
        }

        var photos: [UIImage] = []
        for entry in weekEntries {
            if let filename = entry.photoFilename,
               let photo = PhotoStorage.loadPhoto(filename: filename) {
                photos.append(photo)
            }
        }
        return photos
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                RecapHeaderView(recap: recap)

                // Main Stats
                RecapStatsCard(recap: recap)

                // Streak Info
                if recap.streakStatus.currentStreak > 0 {
                    StreakCard(streakStatus: recap.streakStatus)
                }

                // Comparison
                if let comparison = recap.comparison {
                    ComparisonCard(comparison: comparison)
                }

                // Fun Fact
                FunFactCard(funFact: recap.funFact)

                // Share Button
                Button {
                    // Refresh photos in case new entries were added since onAppear
                    weekPhotos = loadWeekPhotos()
                    showingSharePreview = true
                } label: {
                    Label("Share This Recap", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.dietCokeRed)
                        )
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weekly Recap")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            weekPhotos = loadWeekPhotos()
        }
        .sheet(isPresented: $showingSharePreview) {
            SharePreviewSheet(
                content: recap,
                isPresented: $showingSharePreview,
                isPremium: purchaseService.isPremium,
                initialTheme: .classic,
                availablePhotos: weekPhotos,
                onPremiumTap: {
                    showingSharePreview = false
                    showingPaywall = true
                }
            )
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Header

struct RecapHeaderView: View {
    let recap: WeeklyRecap

    var body: some View {
        VStack(spacing: 8) {
            Text(recap.summaryEmoji)
                .font(.system(size: 60))

            Text("Week of \(recap.weekRangeText)")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text(recap.yearText)
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Stats Card

struct RecapStatsCard: View {
    let recap: WeeklyRecap

    var body: some View {
        VStack(spacing: 20) {
            // Main stat
            VStack(spacing: 4) {
                Text("\(recap.totalDrinks)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.dietCokeCharcoal)

                Text("DC's this week")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Divider()

            // Secondary stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(
                    icon: "flask.fill",
                    value: "\(String(format: "%.0f", recap.totalOunces)) oz",
                    label: "Total Volume"
                )

                StatItem(
                    icon: "number.circle.fill",
                    value: String(format: "%.1f", recap.averagePerDay),
                    label: "Daily Average"
                )

                if let popularType = recap.mostPopularType {
                    StatItem(
                        icon: popularType.icon,
                        value: popularType.shortName,
                        label: "Favorite"
                    )
                }

                StatItem(
                    icon: "square.grid.2x2.fill",
                    value: "\(recap.uniqueTypesCount)",
                    label: "Types Tried"
                )
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.dietCokeRed)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.dietCokeCharcoal)

            Text(label)
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streakStatus: StreakStatus

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(streakStatus.currentStreak) Day Streak")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(streakStatus.statusText)
                    .font(.subheadline)
                    .foregroundColor(streakStatus.statusColor)
            }

            Spacer()

            if streakStatus.wasStreakMaintained {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

// MARK: - Comparison Card

struct ComparisonCard: View {
    let comparison: WeekComparison

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(comparison.trendColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: comparison.trendIcon)
                    .font(.title2)
                    .foregroundColor(comparison.trendColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("vs Last Week")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(comparison.comparisonText)
                    .font(.subheadline)
                    .foregroundColor(comparison.trendColor)
            }

            Spacer()

            if comparison.drinksDelta != 0 {
                Text("\(comparison.drinksDelta > 0 ? "+" : "")\(String(format: "%.0f", comparison.percentageChange))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(comparison.trendColor)
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

// MARK: - Fun Fact Card

struct FunFactCard: View {
    let funFact: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)

            Text(funFact)
                .font(.body)
                .foregroundColor(.dietCokeCharcoal)

            Spacer()
        }
        .padding(20)
        .dietCokeCard()
    }
}

#Preview {
    NavigationStack {
        WeeklyRecapView(recap: WeeklyRecap(
            weekStartDate: Date().addingTimeInterval(-7 * 24 * 3600),
            weekEndDate: Date(),
            totalDrinks: 21,
            totalOunces: 336,
            mostPopularType: .regularCan,
            mostPopularTypeCount: 8,
            uniqueTypesCount: 5,
            averagePerDay: 3.0,
            streakStatus: StreakStatus(currentStreak: 14, wasStreakMaintained: true, streakChange: 7),
            comparison: WeekComparison(drinksDelta: 3, ouncesDelta: 48, percentageChange: 16.7)
        ))
    }
    .environmentObject(DrinkStore())
    .environmentObject(PurchaseService.shared)
}
