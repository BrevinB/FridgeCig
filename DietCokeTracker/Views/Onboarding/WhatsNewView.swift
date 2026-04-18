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
        case "1.2", "1.2.0":
            return [
                WhatsNewFeature(
                    icon: "globe",
                    iconColor: .green,
                    title: "Global Explore Feed",
                    description: "Share your drink photos with the entire community and see what others are sipping. Opt in during onboarding or from Sharing Settings."
                ),
                WhatsNewFeature(
                    icon: "hand.thumbsup.fill",
                    iconColor: .orange,
                    title: "Cheers",
                    description: "Double-tap photos in the Global feed to send cheers to fellow fans."
                ),
                WhatsNewFeature(
                    icon: "ant.fill",
                    iconColor: .dietCokeRed,
                    title: "Bug Fixes & Improvements",
                    description: "Squashed bugs and polished the experience for a smoother ride."
                )
            ]
        case "2.0", "2.0.0":
            return [
                WhatsNewFeature(
                    icon: "rectangle.stack.fill",
                    iconColor: .dietCokeRed,
                    title: "Unified Feed",
                    description: "Friends and Global feeds combined into one tab with a simple toggle. Less tabs, less confusion."
                ),
                WhatsNewFeature(
                    icon: "eye.fill",
                    iconColor: .blue,
                    title: "Post Visibility",
                    description: "Choose who sees each drink: Only Me, Friends, or Public. Your privacy, your choice."
                ),
                WhatsNewFeature(
                    icon: "person.crop.circle.fill",
                    iconColor: .purple,
                    title: "Profile Photos & Emoji",
                    description: "Set a profile photo, take a selfie, or pick an emoji avatar. Show up in feeds and leaderboards with personality."
                ),
                WhatsNewFeature(
                    icon: "person.badge.plus",
                    iconColor: .green,
                    title: "Tap to Add Friends",
                    description: "Tap any username in the feed or leaderboard to view their profile and send a friend request."
                ),
                WhatsNewFeature(
                    icon: "medal.fill",
                    iconColor: .yellow,
                    title: "Friend Badges",
                    description: "View your friends' earned badges on their profile. See who's the biggest collector."
                ),
                WhatsNewFeature(
                    icon: "snowflake",
                    iconColor: .cyan,
                    title: "Streak Freezes Fixed",
                    description: "Pro subscribers now receive 3 freezes monthly. Freezes auto-activate when you miss a day to protect your streak."
                ),
                WhatsNewFeature(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Faster Everything",
                    description: "Parallel friend loading, smart caching, and freshness gates mean the feed loads instantly."
                ),
                WhatsNewFeature(
                    icon: "widget.small.badge.plus",
                    iconColor: .pink,
                    title: "Social Widgets",
                    description: "Medium and large widgets now show your top friend's streak alongside your stats."
                )
            ]
        default:
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
