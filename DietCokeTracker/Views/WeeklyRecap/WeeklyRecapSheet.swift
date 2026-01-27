import SwiftUI

struct WeeklyRecapSheet: View {
    @EnvironmentObject var recapService: WeeklyRecapService
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTheme: RecapCardTheme = .classic
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let recap = recapService.currentRecap {
                    VStack(spacing: 24) {
                        // Card Preview
                        WeeklyRecapCardView(recap: recap, theme: selectedTheme)
                            .frame(maxWidth: 320)
                            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                            .padding(.top)

                        // Theme Selection
                        RecapThemePicker(selectedTheme: $selectedTheme)

                        // Share Button
                        Button {
                            generateAndShare(recap: recap)
                        } label: {
                            Label("Share Your Week", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.dietCokeRed)
                                )
                        }
                        .padding(.horizontal)

                        // View Details Button
                        NavigationLink {
                            WeeklyRecapView(recap: recap)
                        } label: {
                            Text("View Full Recap")
                                .font(.headline)
                                .foregroundColor(.dietCokeRed)
                        }

                        // History Section
                        if !recapService.recapHistory.isEmpty {
                            RecapHistorySection()
                        }
                    }
                    .padding(.bottom, 40)
                } else {
                    // Generate recap if not available
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Generating your recap...")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if recapService.currentRecap == nil {
                    _ = recapService.generateCurrentWeekRecap(
                        entries: store.entries,
                        currentStreak: store.streakDays
                    )
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func generateAndShare(recap: WeeklyRecap) {
        if let image = recapService.generateShareImage(for: recap, theme: selectedTheme) {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - Recap Card View (Preview)

struct WeeklyRecapCardView: View {
    let recap: WeeklyRecap
    let theme: RecapCardTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 16) {
                // Header
                Text("Week of \(recap.weekRangeText)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                // Main stat
                VStack(spacing: 4) {
                    Text("\(recap.totalDrinks)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.primaryTextColor)

                    Text("Diet Cokes")
                        .font(.headline)
                        .foregroundColor(theme.accentColor)
                }

                // Stats row
                HStack(spacing: 20) {
                    MiniStat(value: "\(String(format: "%.0f", recap.totalOunces))oz", label: "Total", theme: theme)

                    if recap.streakStatus.currentStreak > 0 {
                        MiniStat(value: "\(recap.streakStatus.currentStreak)", label: "Streak", theme: theme, icon: "flame.fill")
                    }

                    if let comparison = recap.comparison, comparison.drinksDelta != 0 {
                        MiniStat(
                            value: "\(comparison.drinksDelta > 0 ? "+" : "")\(comparison.drinksDelta)",
                            label: "vs Last",
                            theme: theme,
                            color: comparison.trendColor
                        )
                    }
                }

                // Fun fact
                Text(recap.funFact)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(24)
        }
        .aspectRatio(9.0/16.0, contentMode: .fit)
    }
}

struct MiniStat: View {
    let value: String
    let label: String
    let theme: RecapCardTheme
    var icon: String? = nil
    var color: Color? = nil

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color ?? theme.primaryTextColor)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Theme Picker

struct RecapThemePicker: View {
    @Binding var selectedTheme: RecapCardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Theme")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeDarkSilver)
                .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(RecapCardTheme.allCases) { theme in
                    Button {
                        selectedTheme = theme
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: theme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedTheme == theme ? Color.dietCokeRed : Color.clear, lineWidth: 3)
                                )

                            if selectedTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - History Section

struct RecapHistorySection: View {
    @EnvironmentObject var recapService: WeeklyRecapService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Weeks")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)
                .padding(.horizontal)

            ForEach(recapService.recapHistory.prefix(4)) { recap in
                NavigationLink {
                    WeeklyRecapView(recap: recap)
                } label: {
                    RecapHistoryRow(recap: recap)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top)
    }
}

struct RecapHistoryRow: View {
    let recap: WeeklyRecap

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recap.weekRangeText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                Text("\(recap.totalDrinks) drinks")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Spacer()

            if let comparison = recap.comparison {
                HStack(spacing: 4) {
                    Image(systemName: comparison.trendIcon)
                        .font(.caption)
                    Text("\(comparison.drinksDelta > 0 ? "+" : "")\(comparison.drinksDelta)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(comparison.trendColor)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
    }
}

#Preview {
    WeeklyRecapSheet()
        .environmentObject(WeeklyRecapService())
        .environmentObject(DrinkStore())
        .environmentObject(PurchaseService.shared)
}
