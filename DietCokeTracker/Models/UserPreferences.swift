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
    private let usedFreezeDatesKey = "usedFreezeDates"
    private let lastFreezeGrantMonthKey = "lastFreezeGrantMonth"
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

    @Published var usedFreezeDates: Set<String> {
        didSet {
            sharedDefaults?.set(Array(usedFreezeDates), forKey: usedFreezeDatesKey)
        }
    }

    private var lastFreezeGrantMonth: String {
        get { sharedDefaults?.string(forKey: lastFreezeGrantMonthKey) ?? "" }
        set { sharedDefaults?.set(newValue, forKey: lastFreezeGrantMonthKey) }
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
        self.usedFreezeDates = Set(defaults?.stringArray(forKey: usedFreezeDatesKey) ?? [])
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

    func useStreakFreeze(for date: Date? = nil) -> Bool {
        guard streakFreezeCount > 0 else { return false }

        let freezeDate = date ?? Date()
        let dateKey = Self.dateKey(for: freezeDate)

        guard !usedFreezeDates.contains(dateKey) else { return false }

        streakFreezeCount -= 1
        lastStreakFreezeDate = Date()
        usedFreezeDates.insert(dateKey)
        return true
    }

    func isFrozenDay(_ date: Date) -> Bool {
        usedFreezeDates.contains(Self.dateKey(for: date))
    }

    func addStreakFreezes(_ count: Int) {
        streakFreezeCount = min(streakFreezeCount + count, 6)
    }

    func grantMonthlyFreezesIfNeeded(isPremium: Bool) {
        guard isPremium else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())
        guard lastFreezeGrantMonth != currentMonth else { return }
        addStreakFreezes(3)
        lastFreezeGrantMonth = currentMonth
    }

    func autoUseFreezesIfNeeded(entries: [DrinkEntry]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        let hasEntryYesterday = entries.contains {
            calendar.isDate($0.timestamp, inSameDayAs: yesterday)
        }

        if !hasEntryYesterday && !isFrozenDay(yesterday) && streakFreezeCount > 0 {
            let hadStreakBeforeYesterday = entries.contains {
                guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) else { return false }
                return $0.timestamp < yesterday && $0.timestamp >= twoDaysAgo
            } || isFrozenDay(calendar.date(byAdding: .day, value: -2, to: today) ?? today)

            if hadStreakBeforeYesterday {
                _ = useStreakFreeze(for: yesterday)
            }
        }
    }

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
            usedFreezeDatesKey,
            lastFreezeGrantMonthKey,
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
