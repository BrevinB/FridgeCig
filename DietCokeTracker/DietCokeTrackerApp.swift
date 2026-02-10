import SwiftUI
import Combine
import RevenueCat
import os

@main
struct DietCokeTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var store = DrinkStore()
    @StateObject private var badgeStore = BadgeStore()
    @StateObject private var preferences = UserPreferences()
    @StateObject private var milestoneService = MilestoneCardService()
    @StateObject private var recapService = WeeklyRecapService()

    // Social/Leaderboard services
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var identityService: IdentityService
    @StateObject private var friendService: FriendConnectionService
    @StateObject private var drinkSyncService: DrinkSyncService
    @StateObject private var activityService: ActivityFeedService

    // Notification service
    @StateObject private var notificationService: NotificationService

    // Subscription service
    @StateObject private var purchaseService = PurchaseService.shared

    // Review prompt service
    @StateObject private var reviewService = ReviewPromptService()

    // Offline support
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var offlineQueue = OfflineQueue.shared

    // Deep link handler
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    // Theme manager
    @StateObject private var themeManager = ThemeManager()

    init() {
        let ckManager = CloudKitManager()
        _cloudKitManager = StateObject(wrappedValue: ckManager)
        _identityService = StateObject(wrappedValue: IdentityService(cloudKitManager: ckManager))
        _friendService = StateObject(wrappedValue: FriendConnectionService(cloudKitManager: ckManager))
        _drinkSyncService = StateObject(wrappedValue: DrinkSyncService(cloudKitManager: ckManager))
        _activityService = StateObject(wrappedValue: ActivityFeedService(cloudKitManager: ckManager))
        _notificationService = StateObject(wrappedValue: NotificationService(cloudKitManager: ckManager))

        // Configure RevenueCat - Replace with your API key from RevenueCat dashboard
        PurchaseService.shared.configure(apiKey: "appl_cbqDsdjUplQQKgcSBAFeMuyCHlo")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(badgeStore)
                .environmentObject(preferences)
                .environmentObject(cloudKitManager)
                .environmentObject(identityService)
                .environmentObject(friendService)
                .environmentObject(purchaseService)
                .environmentObject(milestoneService)
                .environmentObject(recapService)
                .environmentObject(activityService)
                .environmentObject(notificationService)
                .environmentObject(reviewService)
                .environmentObject(networkMonitor)
                .environmentObject(offlineQueue)
                .environmentObject(deepLinkHandler)
                .environmentObject(themeManager)
                .onOpenURL { url in
                    _ = deepLinkHandler.handleURL(url)
                }
                .task {
                    // Set up sync services
                    store.syncService = drinkSyncService
                    badgeStore.cloudKitManager = cloudKitManager

                    // Connect notification service to app delegate
                    appDelegate.notificationService = notificationService

                    // Initialize identity and sync data
                    await identityService.initialize()
                    await store.performSync()
                    await badgeStore.performSync()

                    // Load subscription offerings and check status
                    await purchaseService.loadOfferings()
                    await purchaseService.checkSubscriptionStatus()

                    // Sync subscription status and drink entries to Apple Watch
                    WatchConnectivityManager.shared.sendSubscriptionStatus(purchaseService.isPremium)
                    WatchConnectivityManager.shared.syncEntriesToWatch(store.entries)

                    // Configure theme manager with purchase service
                    themeManager.configure(purchaseService: purchaseService)

                    // Update notification authorization status
                    await notificationService.updateAuthorizationStatus()
                }
                .onChange(of: identityService.state) { _, newState in
                    // Sync stats when identity becomes ready (e.g., after profile creation)
                    if newState == .ready {
                        Task {
                            try? await identityService.syncStats(from: store)

                            // Configure activity service with current user
                            if let userID = identityService.currentProfile?.userIDString {
                                activityService.configure(
                                    currentUserID: userID,
                                    friendIDs: Array(friendService.friendIDs)
                                )

                                // Configure notification service with current user
                                await notificationService.configure(
                                    userID: userID,
                                    friendIDs: Array(friendService.friendIDs)
                                )
                            }
                        }
                    }
                }
                .onChange(of: friendService.friends) { _, _ in
                    // Update activity service when friends list changes
                    if let userID = identityService.currentProfile?.userIDString {
                        activityService.configure(
                            currentUserID: userID,
                            friendIDs: Array(friendService.friendIDs)
                        )

                        // Update notification service when friends list changes
                        Task {
                            await notificationService.updateFriends(Array(friendService.friendIDs))
                        }
                    }
                }
                .onReceive(store.entriesDidChange.debounce(for: .seconds(2), scheduler: RunLoop.main)) { _ in
                    Task {
                        try? await identityService.syncStats(from: store)
                    }
                }
                .onReceive(store.entriesDidChange) { _ in
                    // Check for drink count milestones
                    let username = identityService.currentProfile?.username
                    milestoneService.checkForMilestones(
                        drinkCount: store.allTimeCount,
                        streakDays: store.streakDays,
                        username: username
                    )
                }
                .onReceive(store.drinkAdded) { entry, photo in
                    AppLogger.general.debug("Received drinkAdded notification for: \(entry.type.displayName)")

                    // Cancel streak reminder since user logged a drink today
                    notificationService.cancelStreakReminderIfNeeded(hasLoggedToday: true)

                    // Post to activity feed if user has sharing enabled
                    guard let userID = identityService.currentProfile?.userIDString,
                          let displayName = identityService.currentProfile?.displayName else {
                        AppLogger.general.debug("No identity found, skipping activity post")
                        return
                    }

                    AppLogger.activity.debug("Posting drink activity for user: \(displayName)")
                    let isPremium = purchaseService.isPremium
                    Task {
                        await activityService.postDrinkActivity(
                            type: entry.type,
                            note: entry.note,
                            photo: photo,
                            userID: userID,
                            displayName: displayName,
                            entryID: entry.id.uuidString,
                            isPremium: isPremium
                        )
                    }
                }
                .onReceive(badgeStore.badgeUnlocked) { badge in
                    // Post badge unlock to activity feed
                    guard let userID = identityService.currentProfile?.userIDString,
                          let displayName = identityService.currentProfile?.displayName else { return }

                    let isPremium = purchaseService.isPremium
                    Task {
                        await activityService.postBadgeActivity(
                            badge: badge,
                            userID: userID,
                            displayName: displayName,
                            isPremium: isPremium
                        )
                    }
                }
                .onReceive(store.streakChanged) { newStreak in
                    // Post streak milestone to activity feed
                    guard let userID = identityService.currentProfile?.userIDString,
                          let displayName = identityService.currentProfile?.displayName else { return }

                    let isPremium = purchaseService.isPremium
                    Task {
                        await activityService.postStreakActivity(
                            days: newStreak,
                            userID: userID,
                            displayName: displayName,
                            isPremium: isPremium
                        )
                    }
                }
                .onReceive(store.drinkDeleted) { entry in
                    // Delete drink activity from activity feed
                    guard let userID = identityService.currentProfile?.userIDString else { return }

                    Task {
                        await activityService.deleteDrinkActivity(
                            entryID: entry.id.uuidString,
                            userID: userID
                        )
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .networkBecameAvailable)) { _ in
                    // Sync when network becomes available
                    Task {
                        AppLogger.sync.info("Network became available, syncing...")
                        await store.performSync()
                        await badgeStore.performSync()

                        // Process any queued offline operations
                        await offlineQueue.processQueue(networkMonitor: networkMonitor) { operation in
                            return await processOfflineOperation(operation)
                        }
                    }
                }
                .onChange(of: purchaseService.isPremium) { _, isPremium in
                    // Sync subscription status to Apple Watch
                    WatchConnectivityManager.shared.sendSubscriptionStatus(isPremium)
                }
        }
    }

    /// Process a queued offline operation
    private func processOfflineOperation(_ operation: OfflineQueue.PendingOperation) async -> Bool {
        // For now, we just attempt to sync - individual operation handling can be added later
        switch operation.type {
        case .syncDrink:
            await store.performSync()
            return true
        case .postActivity, .sendCheer:
            // Activity operations would be handled here
            return true
        case .sendFriendRequest, .acceptFriendRequest:
            // Friend operations would be handled here
            return true
        case .syncBadge:
            await badgeStore.performSync()
            return true
        }
    }
}
