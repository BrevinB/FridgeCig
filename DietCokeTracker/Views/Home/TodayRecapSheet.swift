import SwiftUI

/// Sheet presented when the user taps the "Today's Recap" daily-summary
/// notification. Surfaces the same numbers the home card shows plus a
/// yesterday comparison and the actual list of today's drinks.
struct TodayRecapSheet: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var todayEntries: [DrinkEntry] {
        store.entries.filter { $0.isToday }
    }

    private var yesterdayCount: Int {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        return store.entriesForDate(yesterday).count
    }

    private var delta: Int { store.todayCount - yesterdayCount }

    private var deltaLabel: String {
        if delta == 0 { return "Same as yesterday" }
        if delta > 0 { return "+\(delta) vs yesterday" }
        return "\(delta) vs yesterday"
    }

    private var deltaColor: Color {
        if delta == 0 { return .secondary }
        return delta > 0 ? .green : .orange
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    statRow
                    yesterdayComparison
                    drinksList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Today's Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 4) {
            Text("\(store.todayCount)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(preferences.defaultBrand.buttonGradient)
                .minimumScaleFactor(0.5)
            Text(store.todayCount == 1
                 ? preferences.defaultBrand.shortName
                 : "\(preferences.defaultBrand.shortName)s today")
                .font(.subheadline.weight(.semibold))
                .tracking(1.5)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)
        )
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            stat(value: String(format: "%.0f", store.todayOunces), label: "OUNCES", icon: "drop.fill", tint: .blue)
            stat(value: "\(store.streakDays)", label: store.streakDays == 1 ? "DAY STREAK" : "DAY STREAK", icon: "flame.fill", tint: .orange)
            stat(value: String(format: "%.1f", store.averagePerDay), label: "AVG/DAY", icon: "chart.bar.fill", tint: .dietCokeRed)
        }
    }

    private var yesterdayComparison: some View {
        HStack(spacing: 12) {
            Image(systemName: delta == 0 ? "equal.circle.fill" : (delta > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"))
                .font(.title2)
                .foregroundColor(deltaColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(deltaLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Yesterday: \(yesterdayCount) \(yesterdayCount == 1 ? "drink" : "drinks")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var drinksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LOGGED TODAY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)
                Spacer()
                if !todayEntries.isEmpty {
                    Text("\(todayEntries.count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.dietCokeRed)
                        .clipShape(Circle())
                }
            }

            if todayEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title)
                        .foregroundColor(.dietCokeDarkSilver)
                    Text("No drinks logged today")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeCharcoal)
                    Text("Streak freezes can save the day — check the streak badge on Home.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEntries) { entry in
                        DrinkRowView(entry: entry)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stat(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(tint)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.dietCokeCharcoal)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#if DEBUG
#Preview("With drinks") {
    TodayRecapSheet().withPreviewEnvironment()
}

#Preview("Empty day") {
    TodayRecapSheet().withPreviewEnvironment(populated: false)
}
#endif
