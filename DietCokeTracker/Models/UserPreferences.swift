import Foundation
import SwiftUI
import Combine

@MainActor
class UserPreferences: ObservableObject {
    // Keys
    private let defaultBrandKey = "defaultBeverageBrand"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let lastSeenVersionKey = "lastSeenAppVersion"
    private let appLaunchCountKey = "appLaunchCount"
    private let hasRequestedReviewKey = "hasRequestedReview"
    private let streakFreezeCountKey = "streakFreezeCount"
    private let lastStreakFreezeDateKey = "lastStreakFreezeDate"
    private let lastUpsellDateKey = "lastUpsellDate"
    private let upsellDrinkTriggerShownKey = "upsellDrinkTriggerShown"
    private let upsellBadgeTriggerShownKey = "upsellBadgeTriggerShown"
    private let upsellStreakTriggerShownKey = "upsellStreakTriggerShown"

    @Published var defaultBrand: BeverageBrand {
        didSet { saveBrand() }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { sharedDefaults?.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey) }
    }

    @Published var lastSeenVersion: String {
        didSet { sharedDefaults?.set(lastSeenVersion, forKey: lastSeenVersionKey) }
    }

    @Published var appLaunchCount: Int {
        didSet { sharedDefaults?.set(appLaunchCount, forKey: appLaunchCountKey) }
    }

    @Published var hasRequestedReview: Bool {
        didSet { sharedDefaults?.set(hasRequestedReview, forKey: hasRequestedReviewKey) }
    }

    @Published var streakFreezeCount: Int {
        didSet { sharedDefaults?.set(streakFreezeCount, forKey: streakFreezeCountKey) }
    }

    @Published var lastStreakFreezeDate: Date? {
        didSet {
            if let date = lastStreakFreezeDate {
                sharedDefaults?.set(date, forKey: lastStreakFreezeDateKey)
            } else {
                sharedDefaults?.removeObject(forKey: lastStreakFreezeDateKey)
            }
        }
    }

    // Upsell trigger tracking
    @Published var lastUpsellDate: Date? {
        didSet {
            if let date = lastUpsellDate {
                sharedDefaults?.set(date, forKey: lastUpsellDateKey)
            } else {
                sharedDefaults?.removeObject(forKey: lastUpsellDateKey)
            }
        }
    }

    @Published var upsellDrinkTriggerShown: Bool {
        didSet { sharedDefaults?.set(upsellDrinkTriggerShown, forKey: upsellDrinkTriggerShownKey) }
    }

    @Published var upsellBadgeTriggerShown: Bool {
        didSet { sharedDefaults?.set(upsellBadgeTriggerShown, forKey: upsellBadgeTriggerShownKey) }
    }

    @Published var upsellStreakTriggerShown: Bool {
        didSet { sharedDefaults?.set(upsellStreakTriggerShown, forKey: upsellStreakTriggerShownKey) }
    }

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupID)
    }

    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var shouldShowWhatsNew: Bool {
        hasCompletedOnboarding && lastSeenVersion != currentAppVersion
    }

    init() {
        let defaults = UserDefaults(suiteName: SharedDataManager.appGroupID)

        // Load saved brand or default to DC
        if let savedValue = defaults?.string(forKey: defaultBrandKey),
           let brand = BeverageBrand(rawValue: savedValue) {
            self.defaultBrand = brand
        } else {
            self.defaultBrand = .dietCoke
        }

        // Load other preferences
        self.lastSeenVersion = defaults?.string(forKey: lastSeenVersionKey) ?? ""
        let savedLaunchCount = defaults?.integer(forKey: appLaunchCountKey) ?? 0
        self.appLaunchCount = savedLaunchCount
        self.hasRequestedReview = defaults?.bool(forKey: hasRequestedReviewKey) ?? false
        self.streakFreezeCount = defaults?.integer(forKey: streakFreezeCountKey) ?? 0
        self.lastStreakFreezeDate = defaults?.object(forKey: lastStreakFreezeDateKey) as? Date
        self.lastUpsellDate = defaults?.object(forKey: lastUpsellDateKey) as? Date
        self.upsellDrinkTriggerShown = defaults?.bool(forKey: upsellDrinkTriggerShownKey) ?? false
        self.upsellBadgeTriggerShown = defaults?.bool(forKey: upsellBadgeTriggerShownKey) ?? false
        self.upsellStreakTriggerShown = defaults?.bool(forKey: upsellStreakTriggerShownKey) ?? false

        // Check if user has completed onboarding
        // For existing users upgrading (appLaunchCount > 0), auto-complete onboarding
        let savedOnboardingState = defaults?.bool(forKey: hasCompletedOnboardingKey) ?? false
        if savedOnboardingState {
            self.hasCompletedOnboarding = true
        } else if savedLaunchCount > 0 {
            // Existing user upgrading - skip onboarding
            self.hasCompletedOnboarding = true
            // Save this so we don't check again
            defaults?.set(true, forKey: hasCompletedOnboardingKey)
        } else {
            // New user - show onboarding
            self.hasCompletedOnboarding = false
        }

        // Increment launch count
        self.appLaunchCount += 1
    }

    private func saveBrand() {
        sharedDefaults?.set(defaultBrand.rawValue, forKey: defaultBrandKey)
    }

    func markOnboardingComplete() {
        hasCompletedOnboarding = true
        lastSeenVersion = currentAppVersion
    }

    func markVersionSeen() {
        lastSeenVersion = currentAppVersion
    }

    func useStreakFreeze() -> Bool {
        guard streakFreezeCount > 0 else { return false }

        // Check if already used today
        if let lastFreeze = lastStreakFreezeDate,
           Calendar.current.isDateInToday(lastFreeze) {
            return false
        }

        streakFreezeCount -= 1
        lastStreakFreezeDate = Date()
        return true
    }

    func addStreakFreezes(_ count: Int) {
        streakFreezeCount += count
    }

    // MARK: - Upsell Triggers

    /// Check if we can show an upsell today (max 1 per day)
    var canShowUpsellToday: Bool {
        guard let lastDate = lastUpsellDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Mark that an upsell was shown today
    func markUpsellShown() {
        lastUpsellDate = Date()
    }

    /// Check if the 5th drink upsell should be shown
    func shouldShowDrinkUpsell(drinkCount: Int) -> Bool {
        return drinkCount == 5 && !upsellDrinkTriggerShown && canShowUpsellToday
    }

    /// Mark the drink upsell as shown
    func markDrinkUpsellShown() {
        upsellDrinkTriggerShown = true
        markUpsellShown()
    }

    /// Check if the first badge upsell should be shown
    func shouldShowBadgeUpsell(isFirstBadge: Bool) -> Bool {
        return isFirstBadge && !upsellBadgeTriggerShown && canShowUpsellToday
    }

    /// Mark the badge upsell as shown
    func markBadgeUpsellShown() {
        upsellBadgeTriggerShown = true
        markUpsellShown()
    }

    /// Check if the 7-day streak upsell should be shown
    func shouldShowStreakUpsell(streakDays: Int) -> Bool {
        return streakDays == 7 && !upsellStreakTriggerShown && canShowUpsellToday
    }

    /// Mark the streak upsell as shown
    func markStreakUpsellShown() {
        upsellStreakTriggerShown = true
        markUpsellShown()
    }

    // MARK: - Data Management

    func exportAllData() -> [String: Any] {
        return [
            "defaultBrand": defaultBrand.rawValue,
            "hasCompletedOnboarding": hasCompletedOnboarding,
            "appLaunchCount": appLaunchCount,
            "streakFreezeCount": streakFreezeCount,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
    }

    func clearAllData() {
        let keys = [
            defaultBrandKey,
            hasCompletedOnboardingKey,
            lastSeenVersionKey,
            appLaunchCountKey,
            hasRequestedReviewKey,
            streakFreezeCountKey,
            lastStreakFreezeDateKey,
            lastUpsellDateKey,
            upsellDrinkTriggerShownKey,
            upsellBadgeTriggerShownKey,
            upsellStreakTriggerShownKey
        ]

        for key in keys {
            sharedDefaults?.removeObject(forKey: key)
        }

        // Reset to defaults
        defaultBrand = .dietCoke
        hasCompletedOnboarding = false
        lastSeenVersion = ""
        appLaunchCount = 0
        hasRequestedReview = false
        streakFreezeCount = 0
        lastStreakFreezeDate = nil
        lastUpsellDate = nil
        upsellDrinkTriggerShown = false
        upsellBadgeTriggerShown = false
        upsellStreakTriggerShown = false
    }
}
