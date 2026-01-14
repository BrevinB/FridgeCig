import SwiftUI

@main
struct DietCokeTrackerApp: App {
    @StateObject private var store = DrinkStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
