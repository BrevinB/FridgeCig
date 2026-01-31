import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var notificationService: NotificationService
    @State private var currentPage = 0
    @State private var selectedBrand: BeverageBrand = .dietCoke
    @Environment(\.colorScheme) private var colorScheme

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark
                ? Color(red: 0.08, green: 0.08, blue: 0.10)
                : Color(red: 0.96, green: 0.96, blue: 0.97))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    FeaturesPage()
                        .tag(1)

                    NotificationsPage(notificationService: notificationService)
                        .tag(2)

                    BrandSelectionPage(selectedBrand: $selectedBrand)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.5))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Continue/Get Started button
                    Button {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 32)

                    // Skip button (not on last page)
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                    } else {
                        // Spacer to maintain layout
                        Text(" ")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        preferences.defaultBrand = selectedBrand
        preferences.markOnboardingComplete()
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated logo/icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dietCokeRed.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: Color.dietCokeRed.opacity(0.5), radius: 20, y: 10)

                // Icon
                Image(systemName: "drop.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.dietCokeDarkSilver)

                Text("FridgeCig")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Track your Diet Coke journey")
                    .font(.body)
                    .foregroundColor(.dietCokeDarkSilver)
                    .padding(.top, 4)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Features Page

private struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("What You Can Do")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.dietCokeCharcoal)

            VStack(spacing: 24) {
                FeatureRow(
                    icon: "plus.circle.fill",
                    color: .dietCokeRed,
                    title: "Log Your Drinks",
                    description: "Track every DC with type, size, and photos"
                )

                FeatureRow(
                    icon: "trophy.fill",
                    color: .orange,
                    title: "Earn Badges",
                    description: "Unlock fun achievements as you drink"
                )

                FeatureRow(
                    icon: "person.2.fill",
                    color: .blue,
                    title: "Compete with Friends",
                    description: "See who's the biggest DC fan"
                )

                FeatureRow(
                    icon: "chart.bar.fill",
                    color: .purple,
                    title: "View Your Stats",
                    description: "Streaks, totals, and weekly recaps"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Spacer()
        }
    }
}

// MARK: - Notifications Page

private struct NotificationsPage: View {
    @ObservedObject var notificationService: NotificationService
    @State private var hasRequested = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("Stay on Track")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Get reminders to maintain your streak and celebrate milestones with friends")
                    .font(.body)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if !hasRequested {
                Button {
                    Task {
                        _ = await notificationService.requestAuthorization()
                        hasRequested = true
                    }
                } label: {
                    Label("Enable Notifications", systemImage: "bell.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notificationService.isAuthorized ? .green : .secondary)
                    Text(notificationService.isAuthorized ? "Notifications enabled!" : "You can enable later in Settings")
                        .font(.subheadline)
                        .foregroundColor(notificationService.isAuthorized ? .green : .secondary)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Brand Selection Page

private struct BrandSelectionPage: View {
    @Binding var selectedBrand: BeverageBrand

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your Go-To Drink")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Select your default beverage.\nYou can always change it when logging.")
                    .font(.body)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(BeverageBrand.allCases) { brand in
                    BrandOptionRow(brand: brand, isSelected: selectedBrand == brand) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedBrand = brand
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

private struct BrandOptionRow: View {
    let brand: BeverageBrand
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [brand.color.opacity(0.2), brand.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: brand.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(brand.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(brand.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)

                    Text(brand.shortName)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [brand.color, brand.color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.title2)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? brand.color.opacity(colorScheme == .dark ? 0.15 : 0.08)
                          : (colorScheme == .dark ? Color(white: 0.12) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? brand.color.opacity(0.5) : Color.dietCokeSilver.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserPreferences())
        .environmentObject(NotificationService(cloudKitManager: CloudKitManager()))
}
