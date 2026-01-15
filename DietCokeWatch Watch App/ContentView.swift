import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var todayCount = 0
    @State private var todayOunces = 0.0
    @State private var streak = 0

    var body: some View {
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
            .navigationTitle("Diet Coke")
            .onAppear(perform: refreshData)
        }
    }

    private func refreshData() {
        todayCount = SharedDataManager.getTodayCount()
        todayOunces = SharedDataManager.getTodayOunces()
        streak = SharedDataManager.getStreak()
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

            Text("Diet Cokes today")
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
    }

    private func addDrink(_ type: DrinkType) {
        let entry = DrinkEntry(type: type)

        guard let defaults = UserDefaults(suiteName: SharedDataManager.appGroupID) else { return }

        var entries: [DrinkEntry] = []
        if let data = defaults.data(forKey: SharedDataManager.entriesKey) {
            entries = (try? JSONDecoder().decode([DrinkEntry].self, from: data)) ?? []
        }

        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }

        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: SharedDataManager.entriesKey)
        }

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
