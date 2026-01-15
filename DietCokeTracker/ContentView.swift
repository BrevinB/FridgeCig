import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @State private var showingAddDrink = false
    @State private var selectedTab = 0
    @State private var showingBadgeToast = false
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(showingAddDrink: $showingAddDrink)
                    .tabItem {
                        Label("Today", systemImage: "house.fill")
                    }
                    .tag(0)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(1)

                BadgesView()
                    .tabItem {
                        Label("Badges", systemImage: "trophy.fill")
                    }
                    .tag(2)

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
            }
            .tint(.dietCokeRed)
            .sheet(isPresented: $showingAddDrink) {
                AddDrinkView()
            }

            // Badge Unlock Toast Overlay
            if showingBadgeToast, let badge = badgeStore.recentlyUnlocked {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissBadgeToast()
                    }

                BadgeUnlockToast(badge: badge) {
                    dismissBadgeToast()
                } onShare: {
                    showingShareSheet = true
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4), value: showingBadgeToast)
        .onChange(of: badgeStore.recentlyUnlocked) { _, newBadge in
            if newBadge != nil {
                showingBadgeToast = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let badge = badgeStore.recentlyUnlocked {
                ShareBadgeSheet(badge: badge)
            }
        }
        .onAppear {
            store.checkBadges(with: badgeStore)
        }
    }

    private func dismissBadgeToast() {
        showingBadgeToast = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            badgeStore.dismissRecentBadge()
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var store: DrinkStore
    @Binding var showingAddDrink: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    TodaySummaryCard()

                    // Quick Add Section
                    QuickAddSection(showingAddDrink: $showingAddDrink)

                    // Today's Drinks
                    TodayDrinksSection()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Diet Coke Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDrink = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }
        }
    }
}

struct TodaySummaryCard: View {
    @EnvironmentObject var store: DrinkStore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                    Text("\(store.todayCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.dietCokeCharcoal)
                    Text(store.todayCount == 1 ? "Diet Coke" : "Diet Cokes")
                        .font(.headline)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.dietCokeRed)

                    Text(String(format: "%.1f oz", store.todayOunces))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)
                }
            }

            if store.streakDays > 1 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(store.streakDays) day streak!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

struct QuickAddSection: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @Binding var showingAddDrink: Bool

    let quickTypes: [DrinkType] = [
        .regularCan,
        .mcdonaldsLarge,
        .bottle20oz,
        .chickfilaLarge
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Add")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Button("See All") {
                    showingAddDrink = true
                }
                .font(.subheadline)
                .foregroundColor(.dietCokeRed)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(quickTypes) { type in
                    QuickAddButton(type: type) {
                        withAnimation(.spring(response: 0.3)) {
                            store.addDrink(type: type)
                            store.checkBadges(with: badgeStore)
                        }
                    }
                }
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

struct TodayDrinksSection: View {
    @EnvironmentObject var store: DrinkStore

    var todayEntries: [DrinkEntry] {
        store.entries.filter { $0.isToday }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Drinks")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            if todayEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 40))
                        .foregroundColor(.dietCokeSilver)
                    Text("No Diet Cokes yet today")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(todayEntries) { entry in
                    DrinkRowView(entry: entry)
                }
            }
        }
        .padding(20)
        .dietCokeCard()
    }
}

#Preview {
    ContentView()
        .environmentObject(DrinkStore())
        .environmentObject(BadgeStore())
}
