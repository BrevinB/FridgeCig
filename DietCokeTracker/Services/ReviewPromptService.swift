import StoreKit
import SwiftUI

/// Service to manage App Store review prompts
/// Follows Apple guidelines to only prompt at appropriate moments
@MainActor
class ReviewPromptService: ObservableObject {
    // Thresholds for prompting
    private let minimumDrinksForFirstPrompt = 10
    private let minimumDrinksForSecondPrompt = 50
    private let minimumDrinksForThirdPrompt = 100
    private let minimumDaysSinceLastPrompt = 30

    // UserDefaults keys
    private let lastPromptDateKey = "lastReviewPromptDate"
    private let promptCountKey = "reviewPromptCount"
    private let lastPromptDrinkCountKey = "lastPromptDrinkCount"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupID)
    }

    private var lastPromptDate: Date? {
        get { sharedDefaults?.object(forKey: lastPromptDateKey) as? Date }
        set { sharedDefaults?.set(newValue, forKey: lastPromptDateKey) }
    }

    private var promptCount: Int {
        get { sharedDefaults?.integer(forKey: promptCountKey) ?? 0 }
        set { sharedDefaults?.set(newValue, forKey: promptCountKey) }
    }

    private var lastPromptDrinkCount: Int {
        get { sharedDefaults?.integer(forKey: lastPromptDrinkCountKey) ?? 0 }
        set { sharedDefaults?.set(newValue, forKey: lastPromptDrinkCountKey) }
    }

    /// Check if we should prompt for review after logging a drink
    func checkForReviewPrompt(totalDrinks: Int, currentStreak: Int) {
        // Don't prompt more than 3 times total
        guard promptCount < 3 else { return }

        // Check minimum days since last prompt
        if let lastPrompt = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysSinceLastPrompt else { return }
        }

        // Determine threshold based on prompt count
        let threshold: Int
        switch promptCount {
        case 0:
            threshold = minimumDrinksForFirstPrompt
        case 1:
            threshold = minimumDrinksForSecondPrompt
        case 2:
            threshold = minimumDrinksForThirdPrompt
        default:
            return
        }

        // Check if we've crossed the threshold since last prompt
        guard totalDrinks >= threshold && lastPromptDrinkCount < threshold else { return }

        // Request the review
        requestReview()

        // Update tracking
        lastPromptDate = Date()
        promptCount += 1
        lastPromptDrinkCount = totalDrinks
    }

    /// Check if we should prompt after a badge unlock
    func checkForReviewAfterBadge(badgeRarity: BadgeRarity, totalBadges: Int) {
        // Prompt after earning an epic or legendary badge
        guard badgeRarity == .epic || badgeRarity == .legendary else { return }

        // Only prompt if we haven't already prompted in last 30 days
        if let lastPrompt = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysSinceLastPrompt else { return }
        }

        // Only prompt if this is at least the 5th badge
        guard totalBadges >= 5 else { return }

        // Don't prompt more than 3 times total
        guard promptCount < 3 else { return }

        // Request the review
        requestReview()

        // Update tracking
        lastPromptDate = Date()
        promptCount += 1
    }

    /// Check if we should prompt after a streak milestone
    func checkForReviewAfterStreak(streakDays: Int) {
        // Prompt at milestone streaks: 7, 30, 100 days
        let milestones = [7, 30, 100]
        guard milestones.contains(streakDays) else { return }

        // Only prompt if we haven't already prompted in last 30 days
        if let lastPrompt = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysSinceLastPrompt else { return }
        }

        // Don't prompt more than 3 times total
        guard promptCount < 3 else { return }

        // Request the review
        requestReview()

        // Update tracking
        lastPromptDate = Date()
        promptCount += 1
    }

    private func requestReview() {
        // Get the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        // Use a slight delay to ensure UI is stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppStore.requestReview(in: windowScene)
        }
    }
}
