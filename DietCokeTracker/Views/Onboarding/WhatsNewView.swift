import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Define what's new for each version
    private var features: [WhatsNewFeature] {
        WhatsNewFeature.featuresForVersion(preferences.currentAppVersion)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("What's New")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.dietCokeCharcoal)

                        Text("Version \(preferences.currentAppVersion)")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .padding(.top, 20)

                    // Features list
                    VStack(spacing: 20) {
                        ForEach(features) { feature in
                            WhatsNewFeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .background(
                (colorScheme == .dark
                    ? Color(red: 0.08, green: 0.08, blue: 0.10)
                    : Color(red: 0.96, green: 0.96, blue: 0.97))
                    .ignoresSafeArea()
            )
            .safeAreaInset(edge: .bottom) {
                Button {
                    preferences.markVersionSeen()
                    dismiss()
                } label: {
                    Text("Continue")
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
                .padding(.bottom, 20)
                .background(
                    (colorScheme == .dark
                        ? Color(red: 0.08, green: 0.08, blue: 0.10)
                        : Color(red: 0.96, green: 0.96, blue: 0.97))
                )
            }
        }
    }
}

// MARK: - Feature Model

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    static func featuresForVersion(_ version: String) -> [WhatsNewFeature] {
        // Add features for each version here
        // This can be expanded as you release new versions
        switch version {
        case "1.0":
            return [
                WhatsNewFeature(
                    icon: "sparkles",
                    iconColor: .dietCokeRed,
                    title: "Welcome to FridgeCig!",
                    description: "Track your DC consumption, earn badges, and compete with friends."
                )
            ]
        case "1.1":
            return [
                WhatsNewFeature(
                    icon: "face.smiling.fill",
                    iconColor: .pink,
                    title: "Fun Achievements",
                    description: "40+ new hilarious badges to unlock and share with friends."
                ),
                WhatsNewFeature(
                    icon: "leaf.fill",
                    iconColor: .yellow,
                    title: "Caffeine Free Options",
                    description: "Now track DC Caffeine Free and Coke Zero Caffeine Free."
                ),
                WhatsNewFeature(
                    icon: "bell.badge.fill",
                    iconColor: .orange,
                    title: "Smart Notifications",
                    description: "Streak reminders and friend activity alerts."
                ),
                WhatsNewFeature(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: "Export Your Data",
                    description: "Download your complete drink history anytime."
                )
            ]
        default:
            // Default features for unknown versions
            return [
                WhatsNewFeature(
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    title: "Bug Fixes & Improvements",
                    description: "Various performance improvements and bug fixes."
                )
            ]
        }
    }
}

// MARK: - Feature Row

private struct WhatsNewFeatureRow: View {
    let feature: WhatsNewFeature
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [feature.iconColor.opacity(0.2), feature.iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    WhatsNewView()
        .environmentObject(UserPreferences())
}
