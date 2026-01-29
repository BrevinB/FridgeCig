import Foundation
import SwiftUI
import UserNotifications

@MainActor
class WeeklyRecapService: ObservableObject {
    @Published private(set) var currentRecap: WeeklyRecap?
    @Published private(set) var recapHistory: [WeeklyRecap] = []
    @Published var showRecapSheet: Bool = false

    private let recapHistoryKey = "WeeklyRecapHistory"
    private let lastRecapDateKey = "LastWeeklyRecapDate"

    init() {
        loadRecapHistory()
    }

    // MARK: - Generate Recap

    /// Generate a recap for the current week
    func generateCurrentWeekRecap(entries: [DrinkEntry], currentStreak: Int) -> WeeklyRecap {
        let calendar = Calendar.current

        // Get current week's date range
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return createEmptyRecap(for: today)
        }

        let weekStart = weekInterval.start
        let weekEnd = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? today

        // Filter entries for this week
        let weekEntries = entries.filter { entry in
            entry.timestamp >= weekStart && entry.timestamp < weekInterval.end
        }

        // Calculate stats
        let totalDrinks = weekEntries.count
        let totalOunces = weekEntries.reduce(0.0) { $0 + $1.ounces }

        // Most popular type
        let typeGroups = Dictionary(grouping: weekEntries) { $0.type }
        let mostPopular = typeGroups.max(by: { $0.value.count < $1.value.count })
        let mostPopularType = mostPopular?.key
        let mostPopularCount = mostPopular?.value.count ?? 0

        // Unique types
        let uniqueTypes = Set(weekEntries.map { $0.type }).count

        // Average per day
        let daysInWeek = 7
        let averagePerDay = Double(totalDrinks) / Double(daysInWeek)

        // Streak status
        let streakStatus = calculateStreakStatus(currentStreak: currentStreak, weekEntries: weekEntries)

        // Comparison with last week
        let comparison = calculateComparison(currentWeekDrinks: totalDrinks, currentWeekOunces: totalOunces, entries: entries, weekStart: weekStart)

        let recap = WeeklyRecap(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalDrinks: totalDrinks,
            totalOunces: totalOunces,
            mostPopularType: mostPopularType,
            mostPopularTypeCount: mostPopularCount,
            uniqueTypesCount: uniqueTypes,
            averagePerDay: averagePerDay,
            streakStatus: streakStatus,
            comparison: comparison
        )

        currentRecap = recap
        return recap
    }

    /// Generate and save a weekly recap (called at end of week)
    func finalizeWeeklyRecap(entries: [DrinkEntry], currentStreak: Int) {
        let recap = generateCurrentWeekRecap(entries: entries, currentStreak: currentStreak)

        // Add to history if not already there
        if !recapHistory.contains(where: { Calendar.current.isDate($0.weekStartDate, inSameDayAs: recap.weekStartDate) }) {
            recapHistory.insert(recap, at: 0)
            saveRecapHistory()
        }

        currentRecap = recap
    }

    // MARK: - Calculations

    private func calculateStreakStatus(currentStreak: Int, weekEntries: [DrinkEntry]) -> StreakStatus {
        // Determine if streak was maintained through the week
        let calendar = Calendar.current
        let daysWithEntries = Set(weekEntries.map { calendar.startOfDay(for: $0.timestamp) })

        // Simple heuristic: if we have entries for most days, streak is likely maintained
        let wasStreakMaintained = daysWithEntries.count >= 5 || currentStreak > 0
        let streakChange = wasStreakMaintained ? max(0, min(currentStreak, 7)) : -currentStreak

        return StreakStatus(
            currentStreak: currentStreak,
            wasStreakMaintained: wasStreakMaintained,
            streakChange: streakChange
        )
    }

    private func calculateComparison(currentWeekDrinks: Int, currentWeekOunces: Double, entries: [DrinkEntry], weekStart: Date) -> WeekComparison? {
        let calendar = Calendar.current

        // Get last week's date range
        guard let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart),
              let lastWeekEnd = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart) else {
            return nil
        }

        // Filter entries for last week
        let lastWeekEntries = entries.filter { entry in
            entry.timestamp >= lastWeekStart && entry.timestamp < lastWeekEnd
        }

        let lastWeekDrinks = lastWeekEntries.count
        let lastWeekOunces = lastWeekEntries.reduce(0.0) { $0 + $1.ounces }

        let drinksDelta = currentWeekDrinks - lastWeekDrinks
        let ouncesDelta = currentWeekOunces - lastWeekOunces

        var percentageChange: Double = 0
        if lastWeekDrinks > 0 {
            percentageChange = Double(drinksDelta) / Double(lastWeekDrinks) * 100
        }

        return WeekComparison(
            drinksDelta: drinksDelta,
            ouncesDelta: ouncesDelta,
            percentageChange: percentageChange
        )
    }

    private func createEmptyRecap(for date: Date) -> WeeklyRecap {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date

        return WeeklyRecap(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalDrinks: 0,
            totalOunces: 0,
            mostPopularType: nil,
            mostPopularTypeCount: 0,
            uniqueTypesCount: 0,
            averagePerDay: 0,
            streakStatus: StreakStatus(currentStreak: 0, wasStreakMaintained: false, streakChange: 0),
            comparison: nil
        )
    }

    // MARK: - Image Generation

    func generateShareImage(for recap: WeeklyRecap, theme: RecapCardTheme) -> UIImage? {
        let cardView = WeeklyRecapShareView(recap: recap, theme: theme)

        let controller = UIHostingController(rootView: cardView)
        let size = CGSize(width: 1080, height: 1920) // 9:16 ratio

        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Notifications (Deprecated - now handled by NotificationService)

    /// @deprecated Use NotificationService instead for notification scheduling
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Persistence

    private func saveRecapHistory() {
        // Keep only last 12 weeks
        let trimmedHistory = Array(recapHistory.prefix(12))

        do {
            let data = try JSONEncoder().encode(trimmedHistory)
            UserDefaults.standard.set(data, forKey: recapHistoryKey)
        } catch {
            print("Failed to save recap history: \(error)")
        }
    }

    private func loadRecapHistory() {
        guard let data = UserDefaults.standard.data(forKey: recapHistoryKey) else { return }

        do {
            recapHistory = try JSONDecoder().decode([WeeklyRecap].self, from: data)
        } catch {
            print("Failed to load recap history: \(error)")
        }
    }

    // MARK: - Debug

    #if DEBUG
    func clearHistory() {
        recapHistory.removeAll()
        saveRecapHistory()
    }

    func generateTestRecap() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today

        currentRecap = WeeklyRecap(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalDrinks: 21,
            totalOunces: 336,
            mostPopularType: .regularCan,
            mostPopularTypeCount: 8,
            uniqueTypesCount: 5,
            averagePerDay: 3.0,
            streakStatus: StreakStatus(currentStreak: 14, wasStreakMaintained: true, streakChange: 7),
            comparison: WeekComparison(drinksDelta: 3, ouncesDelta: 48, percentageChange: 16.7)
        )
    }
    #endif
}

// MARK: - Share View for Rendering

struct WeeklyRecapShareView: View {
    let recap: WeeklyRecap
    let theme: RecapCardTheme

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                // App branding
                Text("FridgeCig")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)

                // Week range
                Text("Week of \(recap.weekRangeText)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)

                Spacer()

                // Main stat
                VStack(spacing: 12) {
                    Text("\(recap.totalDrinks)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(theme.primaryTextColor)

                    Text("Diet Cokes")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                }

                // Secondary stats
                VStack(spacing: 24) {
                    StatRow(label: "Total Volume", value: "\(String(format: "%.0f", recap.totalOunces)) oz", theme: theme)

                    if let popularType = recap.mostPopularType {
                        StatRow(label: "Favorite", value: popularType.shortName, theme: theme)
                    }

                    StatRow(label: "Avg/Day", value: String(format: "%.1f", recap.averagePerDay), theme: theme)
                }

                // Streak badge
                if recap.streakStatus.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                        Text("\(recap.streakStatus.currentStreak) day streak")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                    )
                }

                // Fun fact
                Text(recap.funFact)
                    .font(.system(size: 20))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)

                Spacer()

                // Comparison
                if let comparison = recap.comparison {
                    HStack(spacing: 8) {
                        Image(systemName: comparison.trendIcon)
                        Text(comparison.comparisonText)
                    }
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(comparison.trendColor)
                }

                Spacer()
            }
            .padding(60)
        }
        .frame(width: 1080, height: 1920)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let theme: RecapCardTheme

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 22))
                .foregroundColor(theme.secondaryTextColor)
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.primaryTextColor)
        }
        .padding(.horizontal, 60)
    }
}
