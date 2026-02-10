import Foundation
import SwiftUI

/// Handles deep link navigation for the app
@MainActor
class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    // URL scheme: fridgecig://
    static let urlScheme = "fridgecig"

    // Deep link paths
    enum DeepLinkPath: String {
        case friend = "friend"      // fridgecig://friend/CODE
        case addDrink = "add"       // fridgecig://add
        case stats = "stats"        // fridgecig://stats
        case badges = "badges"      // fridgecig://badges
        case paywall = "paywall"    // fridgecig://paywall
    }

    // Published state for navigation
    @Published var pendingFriendCode: String?
    @Published var shouldNavigateToAddFriend = false
    @Published var shouldNavigateToAddDrink = false
    @Published var shouldNavigateToStats = false
    @Published var shouldNavigateToBadges = false
    @Published var shouldShowPaywall = false

    private init() {}

    /// Generate a shareable deep link URL for a friend code
    static func friendCodeURL(code: String) -> URL {
        URL(string: "\(urlScheme)://\(DeepLinkPath.friend.rawValue)/\(code)")!
    }

    /// Generate a shareable text message with deep link
    static func friendShareText(code: String, displayName: String) -> String {
        let url = friendCodeURL(code: code)
        return "Add me on FridgeCig! Tap here: \(url.absoluteString)"
    }

    /// Handle an incoming URL
    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == Self.urlScheme else {
            return false
        }

        let host = url.host
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case DeepLinkPath.friend.rawValue:
            // fridgecig://friend/CODE
            if let code = pathComponents.first, code.count == 8 {
                pendingFriendCode = code.uppercased()
                shouldNavigateToAddFriend = true
                return true
            }
        case DeepLinkPath.addDrink.rawValue:
            // fridgecig://add
            shouldNavigateToAddDrink = true
            return true
        case DeepLinkPath.stats.rawValue:
            // fridgecig://stats
            shouldNavigateToStats = true
            return true
        case DeepLinkPath.badges.rawValue:
            // fridgecig://badges
            shouldNavigateToBadges = true
            return true
        case DeepLinkPath.paywall.rawValue:
            // fridgecig://paywall
            shouldShowPaywall = true
            return true
        default:
            break
        }

        return false
    }

    /// Clear navigation state after handling
    func clearPendingNavigation() {
        pendingFriendCode = nil
        shouldNavigateToAddFriend = false
        shouldNavigateToAddDrink = false
        shouldNavigateToStats = false
        shouldNavigateToBadges = false
        shouldShowPaywall = false
    }

    /// Clear just the friend code state
    func clearPendingFriendCode() {
        pendingFriendCode = nil
        shouldNavigateToAddFriend = false
    }
}

// MARK: - View Extension for Deep Link Handling

extension View {
    func handleDeepLinks() -> some View {
        self.onOpenURL { url in
            _ = DeepLinkHandler.shared.handleURL(url)
        }
    }
}
