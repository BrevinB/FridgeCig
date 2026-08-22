import Foundation
import TelemetryDeck

/// Thin wrapper around the TelemetryDeck SDK.
///
/// TelemetryDeck is privacy-preserving (anonymized user identifiers, no device
/// fingerprinting), so no ATT prompt is required. Signals sent from DEBUG builds
/// are automatically marked as test signals and filtered out of production charts.
enum TelemetryService {
    /// Call once, as early as possible in the app's lifecycle.
    static func initialize() {
        let config = TelemetryDeck.Config(appID: "85FCB33C-FEAD-41C8-9091-6DB9C9C414BA")
        TelemetryDeck.initialize(config: config)
    }

    /// Send a signal with optional parameters.
    static func signal(_ name: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(name, parameters: parameters)
    }

    // MARK: - App events

    static func drinkLogged(entry: DrinkEntry, hasPhoto: Bool, visibility: PostVisibility) {
        signal("Drink.logged", parameters: [
            "drinkType": entry.type.rawValue,
            "brand": entry.brand.rawValue,
            "hasPhoto": String(hasPhoto),
            "hasNote": String(entry.note?.isEmpty == false),
            "rating": entry.rating.map { String($0.rawValue) } ?? "none",
            "visibility": visibility.rawValue
        ])
    }

    static func drinkDeleted() {
        signal("Drink.deleted")
    }

    static func badgeUnlocked(_ badge: Badge) {
        signal("Badge.unlocked", parameters: [
            "badgeID": badge.id,
            "rarity": badge.rarity.rawValue
        ])
    }

    static func streakReached(days: Int) {
        signal("Streak.reached", parameters: ["days": String(days)])
    }

    // MARK: - Navigation

    static func tabSelected(_ tab: String) {
        signal("Tab.selected", parameters: ["tab": tab])
    }

    static func socialSectionViewed(_ section: String) {
        signal("Social.sectionViewed", parameters: ["section": section])
    }

    static func leaderboardViewed(scope: LeaderboardScope, category: LeaderboardCategory) {
        signal("Leaderboard.viewed", parameters: [
            "scope": scope.rawValue,
            "category": category.rawValue
        ])
    }

    // MARK: - Social

    static func profileCreated() {
        signal("Social.profileCreated")
    }

    static func friendRequestSent() {
        signal("Friend.requestSent")
    }

    static func friendRequestAccepted() {
        signal("Friend.requestAccepted")
    }
}
