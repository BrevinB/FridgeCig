#if DEBUG
import SwiftUI

/// Sample data factories and a one-shot `.withPreviewEnvironment()` modifier
/// so any view can spin up a populated environment in Xcode Previews without
/// reconstructing the whole `@EnvironmentObject` graph by hand.
///
/// Usage:
/// ```
/// #Preview {
///     MyView().withPreviewEnvironment()
/// }
/// ```
///
/// Variants:
/// - `.withPreviewEnvironment(populated: false)` for empty-state previews.
@MainActor
enum PreviewSamples {
    // MARK: - Stores

    static func drinkStore(populated: Bool = true) -> DrinkStore {
        let store = DrinkStore()
        if populated {
            store.addSampleData()
        }
        return store
    }

    static func badgeStore(populated: Bool = true) -> BadgeStore {
        let store = BadgeStore()
        if populated {
            // Unlock a small sample of badges so badge UIs aren't empty.
            store.unlock("first_sip")
            store.unlock("getting_started")
            store.unlock("streak_7")
        }
        return store
    }

    static func stateCanStore(populated: Bool = true) -> StateCanStore {
        let store = StateCanStore()
        if populated {
            store.collect("CA")
            store.collect("NY")
            store.collect("TX")
        }
        return store
    }

    static func userPreferences() -> UserPreferences {
        let prefs = UserPreferences()
        prefs.hasCompletedOnboarding = true
        return prefs
    }

    // MARK: - Services (CloudKit-backed, but inert at init)

    static let cloudKitManager = CloudKitManager()

    static func identityService() -> IdentityService {
        IdentityService(cloudKitManager: cloudKitManager)
    }

    static func friendService() -> FriendConnectionService {
        FriendConnectionService(cloudKitManager: cloudKitManager)
    }

    static func activityService() -> ActivityFeedService {
        ActivityFeedService(cloudKitManager: cloudKitManager)
    }

    static func globalFeedService() -> GlobalFeedService {
        GlobalFeedService(cloudKitManager: cloudKitManager)
    }

    static func notificationService() -> NotificationService {
        NotificationService(cloudKitManager: cloudKitManager)
    }

    static func drinkSyncService() -> DrinkSyncService {
        DrinkSyncService(cloudKitManager: cloudKitManager)
    }

    static func milestoneService() -> MilestoneCardService { MilestoneCardService() }
    static func recapService() -> WeeklyRecapService { WeeklyRecapService() }
    static func reviewService() -> ReviewPromptService { ReviewPromptService() }
    static func themeManager() -> ThemeManager { ThemeManager() }

    // MARK: - Sample Models

    static func sampleActivity(type: ActivityType = .drinkLog) -> ActivityItem {
        ActivityItem(
            userID: "preview-user-1",
            displayName: "Alex",
            type: type,
            timestamp: Date().addingTimeInterval(-3600),
            payload: ActivityPayload(
                drinkType: .regularCan,
                drinkBrand: .dietCoke
            ),
            cheersCount: 4,
            isPremium: true,
            visibility: .friends
        )
    }
}

// MARK: - Environment Injection Modifier

private struct PreviewEnvironmentModifier: ViewModifier {
    let populated: Bool

    func body(content: Content) -> some View {
        content
            .environmentObject(PreviewSamples.drinkStore(populated: populated))
            .environmentObject(PreviewSamples.badgeStore(populated: populated))
            .environmentObject(PreviewSamples.stateCanStore(populated: populated))
            .environmentObject(PreviewSamples.userPreferences())
            .environmentObject(PreviewSamples.cloudKitManager)
            .environmentObject(PreviewSamples.identityService())
            .environmentObject(PreviewSamples.friendService())
            .environmentObject(PurchaseService.shared)
            .environmentObject(PreviewSamples.milestoneService())
            .environmentObject(PreviewSamples.recapService())
            .environmentObject(PreviewSamples.activityService())
            .environmentObject(PreviewSamples.globalFeedService())
            .environmentObject(PreviewSamples.notificationService())
            .environmentObject(PreviewSamples.reviewService())
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(OfflineQueue.shared)
            .environmentObject(DeepLinkHandler.shared)
            .environmentObject(PreviewSamples.themeManager())
    }
}

extension View {
    /// Inject the full app environment for SwiftUI previews. Use `populated: false`
    /// to preview empty-state UIs.
    func withPreviewEnvironment(populated: Bool = true) -> some View {
        modifier(PreviewEnvironmentModifier(populated: populated))
    }
}
#endif
