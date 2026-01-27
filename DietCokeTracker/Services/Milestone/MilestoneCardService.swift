import Foundation
import SwiftUI
import Combine

@MainActor
class MilestoneCardService: ObservableObject {
    @Published var pendingCard: MilestoneCard?
    @Published var selectedTheme: CardTheme = .classic

    private let lastDrinkCountKey = "LastMilestoneDrinkCount"
    private let lastStreakKey = "LastMilestoneStreak"
    private let shownMilestonesKey = "ShownMilestones"

    private var shownMilestones: Set<String> = []

    init() {
        loadShownMilestones()
    }

    // MARK: - Check for Milestones

    /// Check if a new milestone has been reached
    func checkForMilestones(drinkCount: Int, streakDays: Int, username: String? = nil) {
        // Check drink count milestones
        if MilestoneThresholds.isDrinkCountMilestone(drinkCount) {
            let key = "drink_\(drinkCount)"
            if !shownMilestones.contains(key) {
                pendingCard = MilestoneCard.forDrinkCount(drinkCount, username: username)
                markMilestoneShown(key)
            }
        }

        // Check streak milestones
        if MilestoneThresholds.isStreakMilestone(streakDays) {
            let key = "streak_\(streakDays)"
            if !shownMilestones.contains(key) {
                pendingCard = MilestoneCard.forStreak(streakDays, username: username)
                markMilestoneShown(key)
            }
        }
    }

    /// Check if a badge unlock should show a milestone card
    func checkBadgeMilestone(badge: Badge, username: String? = nil) {
        let key = "badge_\(badge.id)"
        if !shownMilestones.contains(key) {
            pendingCard = MilestoneCard.forBadge(badge, username: username)
            markMilestoneShown(key)
        }
    }

    /// Dismiss the pending card
    func dismissCard() {
        pendingCard = nil
    }

    // MARK: - Theme Selection

    func selectTheme(_ theme: CardTheme) {
        selectedTheme = theme
    }

    // MARK: - Generate Card Image

    func generateShareImage(for card: MilestoneCard, theme: CardTheme) -> UIImage? {
        // Create a view to render
        let cardView = MilestoneCardShareView(card: card, theme: theme)

        // Render to image (9:16 aspect ratio for Instagram Stories)
        let controller = UIHostingController(rootView: cardView)
        let size = CGSize(width: 1080, height: 1920) // 9:16 ratio

        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Persistence

    private func markMilestoneShown(_ key: String) {
        shownMilestones.insert(key)
        saveShownMilestones()
    }

    private func saveShownMilestones() {
        let array = Array(shownMilestones)
        UserDefaults.standard.set(array, forKey: shownMilestonesKey)
    }

    private func loadShownMilestones() {
        if let array = UserDefaults.standard.stringArray(forKey: shownMilestonesKey) {
            shownMilestones = Set(array)
        }
    }

    // MARK: - Debug

    #if DEBUG
    func resetShownMilestones() {
        shownMilestones.removeAll()
        saveShownMilestones()
    }

    func showTestCard() {
        pendingCard = MilestoneCard.forDrinkCount(100, username: "TestUser")
    }
    #endif
}

// MARK: - Share View for Rendering

struct MilestoneCardShareView: View {
    let card: MilestoneCard
    let theme: CardTheme

    var body: some View {
        ZStack {
            // Background gradient
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

                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 160, height: 160)

                    Image(systemName: card.icon)
                        .font(.system(size: 80))
                        .foregroundColor(theme.accentColor)
                }

                // Title
                Text(card.title)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(theme.primaryTextColor)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(card.subtitle)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(theme.accentColor)

                // Value/Description
                Text(card.value)
                    .font(.system(size: 24))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Username
                if let username = card.username {
                    Text("@\(username)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.top, 20)
                }

                Spacer()

                // Date
                Text(card.formattedDate)
                    .font(.system(size: 20))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.7))

                Spacer()
            }
            .padding(60)
        }
        .frame(width: 1080, height: 1920)
    }
}
