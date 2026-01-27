import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var milestoneService: MilestoneCardService
    @State private var showingAddDrink = false
    @State private var selectedTab = 0
    @State private var showingBadgeToast = false
    @State private var showingShareSheet = false
    @State private var showingMilestoneCard = false

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

                SocialTabView()
                    .tabItem {
                        Label("Social", systemImage: "person.2.fill")
                    }
                    .tag(2)

                BadgesView()
                    .tabItem {
                        Label("Badges", systemImage: "trophy.fill")
                    }
                    .tag(3)

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(4)
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
        .onChange(of: milestoneService.pendingCard) { _, newCard in
            if newCard != nil {
                showingMilestoneCard = true
            }
        }
        .sheet(isPresented: $showingMilestoneCard) {
            if let card = milestoneService.pendingCard {
                MilestoneCardPreviewSheet(card: card)
                    .onDisappear {
                        milestoneService.dismissCard()
                    }
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
    @State private var showingSettings = false

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
            .navigationTitle("FridgeCig")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
                    Text(store.todayCount == 1 ? "DC" : "DCs")
                        .font(.headline)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "flask.fill")
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
    @EnvironmentObject var preferences: UserPreferences
    @Binding var showingAddDrink: Bool

    @State private var showingRateLimitAlert = false
    @State private var rateLimitMessage = ""
    @State private var showingCamera = false
    @State private var selectedTypeForPhoto: DrinkType?
    @State private var pendingPhoto: UIImage?
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""
    @StateObject private var verificationService = ImageVerificationService()

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

                // Show current default brand
                HStack(spacing: 4) {
                    Image(systemName: preferences.defaultBrand.icon)
                        .font(.caption2)
                    Text(preferences.defaultBrand.shortName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(preferences.defaultBrand.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(preferences.defaultBrand.lightColor)
                .clipShape(Capsule())

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
                        quickAdd(type: type)
                    } onAddWithRating: { rating in
                        quickAddWithRating(type: type, rating: rating)
                    } onAddWithPhoto: {
                        showCameraForType(type)
                    }
                }
            }
        }
        .padding(20)
        .dietCokeCard()
        .alert("Too Fast!", isPresented: $showingRateLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rateLimitMessage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $pendingPhoto)
        }
        .onChange(of: pendingPhoto) { _, newPhoto in
            guard let photo = newPhoto, let type = selectedTypeForPhoto else { return }
            verifyAndAddPhoto(photo, for: type)
        }
        .alert("Not a Diet Coke?", isPresented: $showingVerificationAlert) {
            Button("Use Anyway", role: .destructive) {
                if let photo = pendingPhoto, let type = selectedTypeForPhoto {
                    addDrinkWithPhoto(type: type, photo: photo)
                }
                pendingPhoto = nil
                selectedTypeForPhoto = nil
            }
            Button("Retake", role: .cancel) {
                pendingPhoto = nil
                showingCamera = true
            }
        } message: {
            Text(verificationMessage)
        }
    }

    private func quickAdd(type: DrinkType) {
        let validation = store.validateNewEntry(type: type, customOunces: nil)

        if !validation.isValid {
            rateLimitMessage = validation.errorMessage ?? "Please wait before adding another drink."
            showingRateLimitAlert = true
            return
        }

        withAnimation(.spring(response: 0.3)) {
            store.addDrink(type: type, brand: preferences.defaultBrand)
            store.checkBadges(with: badgeStore)
        }
    }

    private func quickAddWithRating(type: DrinkType, rating: DrinkRating) {
        let validation = store.validateNewEntry(type: type, customOunces: nil)

        if !validation.isValid {
            rateLimitMessage = validation.errorMessage ?? "Please wait before adding another drink."
            showingRateLimitAlert = true
            return
        }

        withAnimation(.spring(response: 0.3)) {
            store.addDrink(type: type, brand: preferences.defaultBrand, rating: rating)
            store.checkBadges(with: badgeStore)
        }
    }

    private func showCameraForType(_ type: DrinkType) {
        let validation = store.validateNewEntry(type: type, customOunces: nil)

        if !validation.isValid {
            rateLimitMessage = validation.errorMessage ?? "Please wait before adding another drink."
            showingRateLimitAlert = true
            return
        }

        selectedTypeForPhoto = type
        showingCamera = true
    }

    private func verifyAndAddPhoto(_ photo: UIImage, for type: DrinkType) {
        guard ImageVerificationService.isAvailable else {
            addDrinkWithPhoto(type: type, photo: photo)
            pendingPhoto = nil
            selectedTypeForPhoto = nil
            return
        }

        Task {
            let result = await verificationService.verifyImage(photo)

            if result.isValid {
                addDrinkWithPhoto(type: type, photo: photo)
                pendingPhoto = nil
                selectedTypeForPhoto = nil
            } else {
                verificationMessage = result.message
                showingVerificationAlert = true
            }
        }
    }

    private func addDrinkWithPhoto(type: DrinkType, photo: UIImage) {
        withAnimation(.spring(response: 0.3)) {
            store.addDrink(type: type, brand: preferences.defaultBrand, photo: photo)
            store.checkBadges(with: badgeStore)
        }
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
                    Text("No DCs yet today")
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
        .environmentObject(MilestoneCardService())
}
