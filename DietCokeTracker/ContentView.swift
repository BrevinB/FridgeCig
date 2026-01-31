import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var milestoneService: MilestoneCardService
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var reviewService: ReviewPromptService
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var offlineQueue: OfflineQueue
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var showingAddDrink = false
    @State private var selectedTab = 0
    @State private var showingBadgeToast = false
    @State private var showingShareSheet = false
    @State private var showingMilestoneCard = false
    @State private var showingWhatsNew = false

    var body: some View {
        ZStack {
            // Show onboarding if not completed
            if !preferences.hasCompletedOnboarding {
                OnboardingView()
            } else {
            VStack(spacing: 0) {
                // Offline banner
                OfflineBanner()

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
            } // End VStack for offline banner

                // Badge Unlock Toast Overlay
                if showingBadgeToast, let badge = badgeStore.recentlyUnlocked {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissBadgeToast()
                        }

                    BadgeUnlockToast(badge: badge, brand: preferences.defaultBrand) {
                        dismissBadgeToast()
                    } onShare: {
                        showingShareSheet = true
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .animation(.spring(response: 0.4), value: showingBadgeToast)
        .onChange(of: badgeStore.recentlyUnlocked) { _, newBadge in
            if let badge = newBadge {
                showingBadgeToast = true
                HapticManager.badgeUnlocked()
                // Check for review prompt after badge unlock
                reviewService.checkForReviewAfterBadge(
                    badgeRarity: badge.rarity,
                    totalBadges: badgeStore.earnedBadges.count
                )
            }
        }
        .onChange(of: store.entries.count) { oldCount, newCount in
            // Check for review prompt after adding drinks
            if newCount > oldCount {
                reviewService.checkForReviewPrompt(
                    totalDrinks: newCount,
                    currentStreak: store.streakDays
                )
            }
        }
        .onChange(of: store.streakDays) { oldStreak, newStreak in
            // Check for review prompt at streak milestones
            if newStreak > oldStreak {
                reviewService.checkForReviewAfterStreak(streakDays: newStreak)
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
                ShareBadgeSheet(badge: badge, brand: preferences.defaultBrand)
            }
        }
        .sheet(isPresented: $showingWhatsNew) {
            WhatsNewView()
        }
        .onAppear {
            store.checkBadges(with: badgeStore)
            // Show What's New if returning user with new version
            if preferences.shouldShowWhatsNew {
                showingWhatsNew = true
            }
        }
        // Deep link navigation handlers
        .onChange(of: deepLinkHandler.shouldNavigateToAddFriend) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 2 // Navigate to Social tab
            }
        }
        .onChange(of: deepLinkHandler.shouldNavigateToAddDrink) { _, shouldNavigate in
            if shouldNavigate {
                showingAddDrink = true
                deepLinkHandler.clearPendingNavigation()
            }
        }
        .onChange(of: deepLinkHandler.shouldNavigateToStats) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 4 // Navigate to Stats tab
                deepLinkHandler.clearPendingNavigation()
            }
        }
        .onChange(of: deepLinkHandler.shouldNavigateToBadges) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 3 // Navigate to Badges tab
                deepLinkHandler.clearPendingNavigation()
            }
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
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showingAddDrink: Bool
    @State private var showingSettings = false
    @State private var celebrationActive = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(red: 0.96, green: 0.96, blue: 0.97))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        TodaySummaryCard()

                        // Quick Add Section
                        QuickAddSection(showingAddDrink: $showingAddDrink)

                        // Today's Drinks
                        TodayDrinksSection()

                        // Bottom spacing for tab bar
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Celebration overlay
                if celebrationActive {
                    FizzBurstView(isActive: $celebrationActive)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("FridgeCig")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDrink = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.dietCokeRed)
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: store.todayCount) { oldValue, newValue in
                // Trigger celebration on new drink
                if newValue > oldValue {
                    celebrationActive = true
                    HapticManager.drinkAdded()
                }
            }
        }
    }
}

struct TodaySummaryCard: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateCount = false
    @State private var showFizz = false
    @State private var showingStreakInfo = false

    var body: some View {
        ZStack {
            // Background with metallic gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)

            // Subtle fizz bubbles
            if showFizz {
                AmbientBubblesBackground(bubbleCount: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)
            }

            // Content
            VStack(spacing: 0) {
                // Top accent bar
                HStack {
                    Text("TODAY")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundColor(.dietCokeRed)

                    Spacer()

                    if store.streakDays > 0 {
                        Button {
                            showingStreakInfo = true
                            HapticManager.lightImpact()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                Text("\(store.streakDays)")
                                    .font(.caption.weight(.bold))
                                if preferences.streakFreezeCount > 0 {
                                    Image(systemName: "snowflake")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                }
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .accessibilityLabel("\(store.streakDays) day streak\(preferences.streakFreezeCount > 0 ? ", \(preferences.streakFreezeCount) freezes available" : "")")
                        .accessibilityHint("Double tap for streak details")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Hero count display
                VStack(spacing: 4) {
                    Text("\(store.todayCount)")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.dietCokeRed, .dietCokeDeepRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(animateCount ? 1.0 : 0.8)
                        .opacity(animateCount ? 1.0 : 0.5)

                    Text(store.todayCount == 1 ? "DIET COKE" : "DIET COKES")
                        .font(.subheadline.weight(.semibold))
                        .tracking(1.5)
                        .foregroundColor(.dietCokeDarkSilver)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(store.todayCount) Diet \(store.todayCount == 1 ? "Coke" : "Cokes") today")

                Spacer()

                // Bottom stats row
                HStack(spacing: 24) {
                    // Ounces stat
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", store.todayOunces))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.dietCokeCharcoal)
                            .minimumScaleFactor(0.8)
                        Text("OUNCES")
                            .font(.caption2.weight(.medium))
                            .tracking(1)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(Int(store.todayOunces)) ounces today")

                    // Divider
                    Rectangle()
                        .fill(Color.dietCokeSilver.opacity(0.3))
                        .frame(width: 1, height: 30)
                        .accessibilityHidden(true)

                    // Average stat
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", store.averagePerDay))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.dietCokeCharcoal)
                            .minimumScaleFactor(0.8)
                        Text("AVG/DAY")
                            .font(.caption2.weight(.medium))
                            .tracking(1)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(String(format: "%.1f", store.averagePerDay)) average per day")

                    // Divider
                    Rectangle()
                        .fill(Color.dietCokeSilver.opacity(0.3))
                        .frame(width: 1, height: 30)
                        .accessibilityHidden(true)

                    // Week stat
                    VStack(spacing: 2) {
                        Text("\(store.thisWeekCount)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.dietCokeCharcoal)
                            .minimumScaleFactor(0.8)
                        Text("THIS WEEK")
                            .font(.caption2.weight(.medium))
                            .tracking(1)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(store.thisWeekCount) this week")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(height: 280)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateCount = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showFizz = true
            }
        }
        .onChange(of: store.todayCount) { _, _ in
            // Animate on count change
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateCount = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animateCount = true
                }
            }
        }
        .sheet(isPresented: $showingStreakInfo) {
            StreakInfoSheet()
        }
    }
}

// MARK: - Streak Info Sheet

struct StreakInfoSheet: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingStreakFreezeUsed = false

    private var hasLoggedToday: Bool {
        store.todayCount > 0
    }

    private var streakAtRisk: Bool {
        !hasLoggedToday && store.streakDays > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak display
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.orange.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)

                            VStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("\(store.streakDays)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)

                                Text(store.streakDays == 1 ? "DAY" : "DAYS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if hasLoggedToday {
                            Label("Streak safe for today!", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else if store.streakDays > 0 {
                            Label("Log a drink to keep your streak!", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 20)

                    Divider()
                        .padding(.horizontal)

                    // Streak Freezes Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "snowflake")
                                .font(.title2)
                                .foregroundColor(.cyan)

                            Text("Streak Freezes")
                                .font(.headline)

                            Spacer()

                            Text("\(preferences.streakFreezeCount) available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("Streak freezes protect your streak for one day when you can't log a drink. They're automatically used at midnight if needed.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if streakAtRisk && preferences.streakFreezeCount > 0 {
                            Button {
                                useStreakFreeze()
                            } label: {
                                HStack {
                                    Image(systemName: "snowflake")
                                    Text("Use Streak Freeze Now")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                            }
                        }

                        // How to earn freezes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to earn freezes:")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.dietCokeRed)
                                Text("Pro subscribers get 3 freezes per month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                Text("Earn freezes by reaching streak milestones")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(
                (colorScheme == .dark
                    ? Color(red: 0.08, green: 0.08, blue: 0.10)
                    : Color(red: 0.96, green: 0.96, blue: 0.97))
                    .ignoresSafeArea()
            )
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Streak Protected!", isPresented: $showingStreakFreezeUsed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your streak is now protected for today. You have \(preferences.streakFreezeCount) freezes remaining.")
            }
        }
    }

    private func useStreakFreeze() {
        if preferences.useStreakFreeze() {
            HapticManager.success()
            showingStreakFreezeUsed = true
        }
    }
}

struct QuickAddSection: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var preferences: UserPreferences
    @Binding var showingAddDrink: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingRateLimitAlert = false
    @State private var rateLimitMessage = ""
    @State private var showingCamera = false
    @State private var selectedTypeForPhoto: DrinkType?
    @State private var pendingPhoto: UIImage?
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""
    @State private var selectedBrand: BeverageBrand = .dietCoke
    @StateObject private var verificationService = ImageVerificationService()

    let quickTypes: [DrinkType] = [
        .regularCan,
        .bottle20oz
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with brand toggle
            HStack {
                Text("QUICK ADD")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()

                // Brand toggle
                HStack(spacing: 0) {
                    ForEach([BeverageBrand.dietCoke, BeverageBrand.cokeZero], id: \.self) { brand in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedBrand = brand
                            }
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            Text(brand.shortName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedBrand == brand ? .white : .dietCokeCharcoal)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedBrand == brand ? brand.color : Color.clear
                                )
                        }
                    }
                }
                .background(Color.dietCokeSilver.opacity(0.15))
                .clipShape(Capsule())

                Button {
                    showingAddDrink = true
                } label: {
                    Text("More")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dietCokeRed)
                }
                .padding(.leading, 8)
            }

            // Quick add buttons - 2 columns
            HStack(spacing: 12) {
                ForEach(quickTypes) { type in
                    QuickAddButton(type: type, brand: selectedBrand) {
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
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
        .onAppear {
            selectedBrand = preferences.defaultBrand
        }
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
            store.addDrink(type: type, brand: selectedBrand)
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
            store.addDrink(type: type, brand: selectedBrand, rating: rating)
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
            store.addDrink(type: type, brand: selectedBrand, photo: photo)
            store.checkBadges(with: badgeStore)
        }
    }
}

struct TodayDrinksSection: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

    var todayEntries: [DrinkEntry] {
        store.entries.filter { $0.isToday }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("TODAY'S DRINKS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()

                if !todayEntries.isEmpty {
                    Text("\(todayEntries.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.dietCokeRed)
                        .clipShape(Circle())
                }
            }

            if todayEntries.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.dietCokeSilver.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "drop.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.dietCokeSilver.opacity(0.5), .dietCokeSilver.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    VStack(spacing: 4) {
                        Text("No drinks yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.dietCokeCharcoal)
                        Text("Tap Quick Add above to log your first DC")
                            .font(.system(size: 13))
                            .foregroundColor(.dietCokeDarkSilver)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Drinks list
                VStack(spacing: 8) {
                    ForEach(todayEntries) { entry in
                        DrinkRowView(entry: entry)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(DrinkStore())
        .environmentObject(BadgeStore())
        .environmentObject(MilestoneCardService())
}
