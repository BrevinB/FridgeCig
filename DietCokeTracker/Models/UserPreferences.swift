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

        // Load saved brand or default to Diet Coke
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
            lastStreakFreezeDateKey
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
    }
}
