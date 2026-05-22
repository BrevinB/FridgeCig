import SwiftUI

struct TodaySummaryCard: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateCount = false
    @State private var showFizz = false
    @State private var showingStreakInfo = false
    @State private var streakIncludesFreeze = false

    private static func computeStreakIncludesFreeze(streakDays: Int, frozenDates: Set<String>) -> Bool {
        guard streakDays > 0, !frozenDates.isEmpty else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<streakDays {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            if frozenDates.contains(UserPreferences.dateKey(for: date)) { return true }
        }
        return false
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    themeManager.currentTheme == .classic
                        ? (colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)
                        : themeManager.primaryGradient
                )

            if showFizz {
                AmbientBubblesBackground(bubbleCount: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)
            }

            VStack(spacing: 0) {
                topRow
                Spacer()
                heroCount
                Spacer()
                bottomStats
            }
        }
        .frame(height: 280)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { animateCount = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showFizz = true }
            streakIncludesFreeze = Self.computeStreakIncludesFreeze(
                streakDays: store.streakDays,
                frozenDates: preferences.usedFreezeDates
            )
        }
        .onChange(of: store.todayCount) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { animateCount = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { animateCount = true }
            }
        }
        .onChange(of: store.streakDays) { _, newValue in
            streakIncludesFreeze = Self.computeStreakIncludesFreeze(
                streakDays: newValue,
                frozenDates: preferences.usedFreezeDates
            )
        }
        .onChange(of: preferences.usedFreezeDates) { _, newValue in
            streakIncludesFreeze = Self.computeStreakIncludesFreeze(
                streakDays: store.streakDays,
                frozenDates: newValue
            )
        }
        .sheet(isPresented: $showingStreakInfo) {
            StreakInfoSheet()
        }
    }

    private var topRow: some View {
        HStack {
            Text("TODAY")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(
                    themeManager.currentTheme == .classic
                        ? AnyShapeStyle(preferences.defaultBrand.iconGradient)
                        : AnyShapeStyle(Color.white.opacity(0.9))
                )

            Spacer()

            if store.streakDays > 0 {
                Button {
                    showingStreakInfo = true
                    HapticManager.lightImpact()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.caption)
                        Text("\(store.streakDays)").font(.caption.weight(.bold))
                        if streakIncludesFreeze {
                            Image(systemName: "snowflake")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
                .accessibilityLabel("\(store.streakDays) day streak\(preferences.streakFreezeCount > 0 ? ", \(preferences.streakFreezeCount) freezes available" : "")")
                .accessibilityHint("Double tap for streak details")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var heroCount: some View {
        VStack(spacing: 4) {
            Text("\(store.todayCount)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .minimumScaleFactor(0.5)
                .foregroundStyle(
                    themeManager.currentTheme == .classic
                        ? AnyShapeStyle(preferences.defaultBrand.buttonGradient)
                        : AnyShapeStyle(Color.white)
                )
                .scaleEffect(animateCount ? 1.0 : 0.8)
                .opacity(animateCount ? 1.0 : 0.5)

            Text(store.todayCount == 1 ? preferences.defaultBrand.shortName : "\(preferences.defaultBrand.shortName)s")
                .font(.subheadline.weight(.semibold))
                .tracking(1.5)
                .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeDarkSilver : .white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.todayCount) \(preferences.defaultBrand.rawValue)\(store.todayCount == 1 ? "" : "s") today")
    }

    private var bottomStats: some View {
        HStack(spacing: 24) {
            stat(value: String(format: "%.0f", store.todayOunces), label: "OUNCES",
                 accessibility: "\(Int(store.todayOunces)) ounces today")
            divider
            stat(value: String(format: "%.1f", store.averagePerDay), label: "AVG/DAY",
                 accessibility: "\(String(format: "%.1f", store.averagePerDay)) average per day")
            divider
            stat(value: "\(store.thisWeekCount)", label: "THIS WEEK",
                 accessibility: "\(store.thisWeekCount) this week")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme == .classic ? Color.dietCokeSilver.opacity(0.3) : Color.white.opacity(0.3))
            .frame(width: 1, height: 30)
            .accessibilityHidden(true)
    }

    private func stat(value: String, label: String, accessibility: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeCharcoal : .white)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2.weight(.medium))
                .tracking(1)
                .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeDarkSilver : .white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibility)
    }
}

#if DEBUG
#Preview {
    TodaySummaryCard()
        .padding()
        .withPreviewEnvironment()
}
#endif
