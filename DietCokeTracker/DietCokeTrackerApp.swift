import SwiftUI
import Combine

@main
struct DietCokeTrackerApp: App {
    @StateObject private var store = DrinkStore()
    @StateObject private var badgeStore = BadgeStore()
    @StateObject private var preferences = UserPreferences()

    // Social/Leaderboard services
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var identityService: IdentityService
    @StateObject private var friendService: FriendConnectionService
    @StateObject private var contactsService = ContactsService()
    @StateObject private var drinkSyncService: DrinkSyncService

    init() {
        let ckManager = CloudKitManager()
        _cloudKitManager = StateObject(wrappedValue: ckManager)
        _identityService = StateObject(wrappedValue: IdentityService(cloudKitManager: ckManager))
        _friendService = StateObject(wrappedValue: FriendConnectionService(cloudKitManager: ckManager))
        _drinkSyncService = StateObject(wrappedValue: DrinkSyncService(cloudKitManager: ckManager))
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
                .environmentObject(contactsService)
                .task {
                    // Set up sync services
                    store.syncService = drinkSyncService
                    badgeStore.cloudKitManager = cloudKitManager

                    // Initialize identity and sync data
                    await identityService.initialize()
                    await store.performSync()
                    await badgeStore.performSync()
                }
                .onChange(of: identityService.state) { _, newState in
                    // Sync stats when identity becomes ready (e.g., after profile creation)
                    if newState == .ready {
                        Task {
                            try? await identityService.syncStats(from: store)
                        }
                    }
                }
                .onReceive(store.entriesDidChange.debounce(for: .seconds(2), scheduler: RunLoop.main)) { _ in
                    Task {
                        try? await identityService.syncStats(from: store)
                    }
                }
        }
    }
}
