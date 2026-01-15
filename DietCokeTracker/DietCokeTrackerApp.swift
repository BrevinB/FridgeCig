import SwiftUI

@main
struct DietCokeTrackerApp: App {
    @StateObject private var store = DrinkStore()
    @StateObject private var badgeStore = BadgeStore()
    @StateObject private var preferences = UserPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(badgeStore)
                .environmentObject(preferences)
        }
    }
}
