import Foundation

struct SubscriptionStatusManager {
    static let appGroupID = "group.co.brevinb.fridgecig"
    static let isPremiumKey = "IsPremiumSubscriber"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func isPremium() -> Bool {
        sharedDefaults?.bool(forKey: isPremiumKey) ?? false
    }

    static func setIsPremium(_ value: Bool) {
        sharedDefaults?.set(value, forKey: isPremiumKey)
    }
}
