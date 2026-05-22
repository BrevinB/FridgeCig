import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var releases: [WhatsNewRelease] {
        WhatsNewRelease.allReleases
    }

    private var latestVersion: String? {
        releases.first?.version
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("What's New")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.dietCokeCharcoal)

                        if let latest = latestVersion {
                            Text("Latest: v\(latest)")
                                .font(.subheadline)
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                    }
                    .padding(.top, 20)

                    VStack(spacing: 28) {
                        ForEach(releases) { release in
                            WhatsNewReleaseSection(
                                release: release,
                                isLatest: release.version == latestVersion
                            )
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

// MARK: - Release Model

struct WhatsNewRelease: Identifiable {
    let id: String
    let version: String
    let features: [WhatsNewFeature]

    init(version: String, features: [WhatsNewFeature]) {
        self.id = version
        self.version = version
        self.features = features
    }

    /// Releases in reverse chronological order — newest first.
    static let allReleases: [WhatsNewRelease] = [
        WhatsNewRelease(version: "2.2.0", features: [
            WhatsNewFeature(
                icon: "bell.badge.fill",
                iconColor: .orange,
                title: "Today's Recap",
                description: "Get an end-of-day notification with your drinks, ounces, and streak — and see how you stacked up against yesterday."
            ),
            WhatsNewFeature(
                icon: "applewatch",
                iconColor: .blue,
                title: "Better Apple Watch Sync",
                description: "Drinks you log on your phone now show up on your Watch faster and stay reliably in sync."
            ),
            WhatsNewFeature(
                icon: "bolt.fill",
                iconColor: .yellow,
                title: "Faster & Smoother",
                description: "Snappier logging, cleaner animations, and a batch of bug fixes throughout the app."
            )
        ]),
        WhatsNewRelease(version: "2.0", features: [
            WhatsNewFeature(
                icon: "rectangle.stack.fill",
                iconColor: .dietCokeRed,
                title: "Unified Feed",
                description: "Friends and Global feeds combined into one tab with a simple toggle."
            ),
            WhatsNewFeature(
                icon: "eye.fill",
                iconColor: .blue,
                title: "Post Visibility",
                description: "Choose who sees each drink: Only Me, Friends, or Public."
            ),
            WhatsNewFeature(
                icon: "person.crop.circle.fill",
                iconColor: .purple,
                title: "Profile Photos & Emoji",
                description: "Set a profile photo or pick an emoji avatar to show up in feeds and leaderboards."
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
                description: "View your friends' earned badges on their profile."
            ),
            WhatsNewFeature(
                icon: "snowflake",
                iconColor: .cyan,
                title: "Streak Freezes Fixed",
                description: "Pro subscribers get 3 freezes monthly. They auto-activate when you miss a day."
            ),
            WhatsNewFeature(
                icon: "widget.small.badge.plus",
                iconColor: .pink,
                title: "Social Widgets",
                description: "Medium and large widgets now show your top friend's streak alongside your stats."
            )
        ]),
        WhatsNewRelease(version: "1.2", features: [
            WhatsNewFeature(
                icon: "globe",
                iconColor: .green,
                title: "Global Explore Feed",
                description: "Share your drink photos with the community and see what others are sipping."
            ),
            WhatsNewFeature(
                icon: "hand.thumbsup.fill",
                iconColor: .orange,
                title: "Cheers",
                description: "Double-tap photos in the Global feed to send cheers to fellow fans."
            )
        ]),
        WhatsNewRelease(version: "1.1", features: [
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
                description: "Track DC Caffeine Free and Coke Zero Caffeine Free."
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
        ]),
        WhatsNewRelease(version: "1.0", features: [
            WhatsNewFeature(
                icon: "sparkles",
                iconColor: .dietCokeRed,
                title: "Welcome to FridgeCig!",
                description: "Track your DC consumption, earn badges, and compete with friends."
            )
        ])
    ]
}

// MARK: - Feature Model

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

// MARK: - Release Section

private struct WhatsNewReleaseSection: View {
    let release: WhatsNewRelease
    let isLatest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Version \(release.version)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(.dietCokeCharcoal)

                if isLatest {
                    Text("LATEST")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.dietCokeRed)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(release.features) { feature in
                    WhatsNewFeatureRow(feature: feature)
                }
            }
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

#if DEBUG
#Preview {
    WhatsNewView().withPreviewEnvironment()
}
#endif
