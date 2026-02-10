import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @State private var todayCount = 0
    @State private var todayOunces = 0.0
    @State private var streak = 0

    var body: some View {
        if connectivity.isPremium {
            mainContent
        } else {
            WatchUpgradePromptView()
                .onAppear {
                    connectivity.requestSubscriptionStatus()
                }
        }
    }

    private var mainContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today's stats
                    TodayCard(count: todayCount, ounces: todayOunces, streak: streak)

                    // Quick add buttons
                    QuickAddSection(onAdd: refreshData)
                }
                .padding(.horizontal)
            }
            .navigationTitle("DC")
            .onAppear {
                refreshData()
                // Request data sync from iPhone
                connectivity.requestDataSync()
            }
            .onChange(of: connectivity.entriesDidUpdate) { _, didUpdate in
                if didUpdate {
                    refreshData()
                    // Reset the flag
                    connectivity.entriesDidUpdate = false
                }
            }
        }
    }

    private func refreshData() {
        todayCount = WatchDataManager.getTodayCount()
        todayOunces = WatchDataManager.getTodayOunces()
        streak = WatchDataManager.getStreak()
    }
}

// MARK: - Upgrade Prompt View

struct WatchUpgradePromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("FridgeCig Pro")
                .font(.headline)

            Text("Open iPhone app to upgrade")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Today Card

struct TodayCard: View {
    let count: Int
    let ounces: Double
    let streak: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.red)

            Text("DCs today")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("\(Int(ounces)) oz", systemImage: "drop.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if streak > 1 {
                    Label("\(streak) days", systemImage: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Add Section

struct QuickAddSection: View {
    let onAdd: () -> Void

    @State private var showingRateLimitAlert = false
    @State private var rateLimitMessage = ""

    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Add")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Primary button - Regular Can
            Button(action: { addDrink(.regularCan) }) {
                HStack {
                    Image(systemName: "cylinder.fill")
                    Text("Regular Can")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            // Secondary buttons
            HStack(spacing: 8) {
                Button(action: { addDrink(.bottle20oz) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "flask.fill")
                        Text("20oz")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { addDrink(.mcdonaldsLarge) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "m.circle.fill")
                        Text("McD's")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .alert("Too Fast!", isPresented: $showingRateLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rateLimitMessage)
        }
    }

    private func addDrink(_ type: DrinkType) {
        // Check rate limiting
        let (allowed, message) = WatchDataManager.canAddEntry()
        guard allowed else {
            rateLimitMessage = message ?? "Please wait before adding another drink."
            showingRateLimitAlert = true
            WKInterfaceDevice.current().play(.failure)
            return
        }

        let entry = DrinkEntry(type: type)

        // Save locally and sync to iPhone
        WatchDataManager.addEntry(entry)

        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)

        // Refresh UI
        onAdd()
    }
}

#Preview {
    ContentView()
}
