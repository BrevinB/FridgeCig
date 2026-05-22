import SwiftUI

struct StreakInfoSheet: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingStreakFreezeUsed = false

    private var hasLoggedToday: Bool {
        store.todayCount > 0
    }

    private var streakAtRisk: Bool {
        !hasLoggedToday && store.streakDays > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    streakBadge
                    Divider().padding(.horizontal)
                    freezesSection
                    Spacer()
                }
            }
            .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Streak Protected!", isPresented: $showingStreakFreezeUsed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your streak is now protected for today. You have \(preferences.streakFreezeCount) freezes remaining.")
            }
        }
    }

    private var streakBadge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("\(store.streakDays)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Text(store.streakDays == 1 ? "DAY" : "DAYS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            if hasLoggedToday {
                Label("Streak safe for today!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else if store.streakDays > 0 {
                Label("Log a drink to keep your streak!", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.top, 20)
    }

    private var freezesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundColor(.cyan)

                Text("Streak Freezes")
                    .font(.headline)

                Spacer()

                Text("\(preferences.streakFreezeCount) available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Streak freezes protect your streak for one day when you can't log a drink. They're automatically used at midnight if needed.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if streakAtRisk && preferences.streakFreezeCount > 0 {
                Button {
                    useStreakFreeze()
                } label: {
                    HStack {
                        Image(systemName: "snowflake")
                        Text("Use Streak Freeze Now")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How to earn freezes:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Image(systemName: "crown.fill").foregroundColor(.dietCokeRed)
                    Text("Pro subscribers get 3 freezes per month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.orange)
                    Text("Earn freezes by reaching streak milestones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func useStreakFreeze() {
        if preferences.useStreakFreeze() {
            HapticManager.success()
            showingStreakFreezeUsed = true
        }
    }
}

#if DEBUG
#Preview {
    StreakInfoSheet().withPreviewEnvironment()
}
#endif
