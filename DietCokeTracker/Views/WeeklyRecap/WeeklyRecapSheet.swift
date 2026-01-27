import SwiftUI

struct WeeklyRecapSheet: View {
    @EnvironmentObject var recapService: WeeklyRecapService
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var showingSharePreview = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let recap = recapService.currentRecap {
                    VStack(spacing: 20) {
                        // Card Preview using new ShareCardView
                        ShareCardPreviewContainer(
                            content: recap,
                            customization: .recapDefault
                        )
                        .frame(height: 280)
                        .padding(.top)

                        // Share section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share Your Week")
                                .font(.headline)
                                .foregroundColor(.dietCokeCharcoal)

                            Text("Create beautiful share cards with themes, stickers, and multiple formats.")
                                .font(.subheadline)
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        // Share Button - opens new SharePreviewSheet
                        Button {
                            showingSharePreview = true
                        } label: {
                            Label("Customize & Share", systemImage: "square.and.arrow.up")
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

                        // Premium features callout
                        if !purchaseService.isPremium {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("Premium unlocks 8 extra themes, stickers, and more formats")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                            .padding(.horizontal)
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
        .sheet(isPresented: $showingSharePreview) {
            if let recap = recapService.currentRecap {
                SharePreviewSheet(
                    content: recap,
                    isPresented: $showingSharePreview,
                    isPremium: purchaseService.isPremium,
                    initialTheme: .classic,
                    onPremiumTap: {
                        showingSharePreview = false
                        showingPaywall = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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
