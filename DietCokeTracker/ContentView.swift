import SwiftUI

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
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var activityService: ActivityFeedService

    @State private var showingAddDrink = false
    // Celebration is queued while the AddDrink sheet is still up, then
    // presented from its onDismiss so the two sheets never collide.
    @State private var pendingCelebration: LoggedDrinkCelebration?
    @State private var presentedCelebration: LoggedDrinkCelebration?
    @State private var selectedTab: RootTab = .today
    @State private var showingBadgeToast = false
    @State private var showingShareSheet = false
    @State private var showingMilestoneCard = false
    @State private var showingWhatsNew = false
    @State private var showingPaywallFromDeepLink = false
    @State private var showingTodayRecap = false

    enum RootTab { case today, history, social, badges, cans, stats, settings }

    var body: some View {
        mainContent
            .animation(.spring(response: 0.4), value: showingBadgeToast)
            .modifier(ContentViewChangeHandlers(
                badgeStore: badgeStore,
                store: store,
                reviewService: reviewService,
                milestoneService: milestoneService,
                showingBadgeToast: $showingBadgeToast,
                showingMilestoneCard: $showingMilestoneCard
            ))
            .modifier(ContentViewSheets(
                milestoneService: milestoneService,
                badgeStore: badgeStore,
                preferences: preferences,
                reviewService: reviewService,
                showingMilestoneCard: $showingMilestoneCard,
                showingShareSheet: $showingShareSheet,
                showingWhatsNew: $showingWhatsNew,
                showingPaywallFromDeepLink: $showingPaywallFromDeepLink,
                showingTodayRecap: $showingTodayRecap
            ))
            .modifier(ContentViewDeepLinks(
                deepLinkHandler: deepLinkHandler,
                selectedTab: $selectedTab,
                showingAddDrink: $showingAddDrink,
                showingPaywallFromDeepLink: $showingPaywallFromDeepLink,
                showingTodayRecap: $showingTodayRecap
            ))
            .onAppear {
                store.checkBadges(with: badgeStore)
                if preferences.shouldShowWhatsNew {
                    showingWhatsNew = true
                }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if !preferences.hasCompletedOnboarding {
                OnboardingView {
                    showingAddDrink = true
                }
            } else {
                VStack(spacing: 0) {
                    OfflineBanner()
                    SyncErrorBanner()

                    TabView(selection: $selectedTab) {
                        Tab("Today", systemImage: "house.fill", value: .today) {
                            HomeView(showingAddDrink: $showingAddDrink)
                        }
                        Tab("Social", systemImage: "person.2.fill", value: .social) {
                            SocialTabView()
                        }
                        Tab("Badges", systemImage: "trophy.fill", value: .badges) {
                            BadgesView()
                        }
                        Tab("Cans", systemImage: "flag.checkered", value: .cans) {
                            StateCansView()
                        }
                        Tab("Stats", systemImage: "chart.bar.fill", value: .stats) {
                            StatsView()
                        }
                        Tab("History", systemImage: "clock.fill", value: .history) {
                            HistoryView()
                        }
                        Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                            SettingsView(hidesDoneButton: true)
                        }
                    }
                    .tint(themeManager.primaryColor)
                    .onChange(of: selectedTab) { _, newTab in
                        TelemetryService.tabSelected(String(describing: newTab))
                    }
                    .sheet(isPresented: $showingAddDrink, onDismiss: {
                        if let celebration = pendingCelebration {
                            pendingCelebration = nil
                            presentedCelebration = celebration
                        }
                    }) {
                        AddDrinkView()
                    }
                    .onChange(of: showingAddDrink) { _, isPresented in
                        if isPresented {
                            TelemetryService.addDrinkOpened()
                        }
                    }
                    .sheet(item: $presentedCelebration) { celebration in
                        DrinkLoggedSheet(celebration: celebration)
                    }
                    .onReceive(store.drinkAdded) { entry, photo, visibility in
                        // Only celebrate logs made through the AddDrink sheet;
                        // widget/App Intent quick-adds shouldn't pop UI.
                        guard showingAddDrink else { return }
                        let prefs = activityService.sharingPreferences
                        let willPostGlobally = photo != nil
                            && visibility == .public
                            && prefs.shareDrinkLogs
                            && prefs.showPhotosInFeed
                            && prefs.sharePhotosGlobally
                        pendingCelebration = LoggedDrinkCelebration(
                            entry: entry,
                            photo: photo,
                            visibility: visibility,
                            willPostGlobally: willPostGlobally
                        )
                    }
                }

                badgeToastOverlay
            }
        }
    }

    @ViewBuilder
    private var badgeToastOverlay: some View {
        if showingBadgeToast, let badge = badgeStore.recentlyUnlocked {
            Button(action: dismissBadgeToast) {
                Color.black.opacity(0.4).ignoresSafeArea()
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Dismiss badge Toast")

            BadgeUnlockToast(badge: badge, brand: preferences.defaultBrand) {
                dismissBadgeToast()
            } onShare: {
                showingShareSheet = true
            }
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
        }
    }

    private func dismissBadgeToast() {
        let dismissedBadge = badgeStore.recentlyUnlocked
        showingBadgeToast = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            if let badge = dismissedBadge {
                reviewService.checkForReviewAfterBadge(
                    badgeRarity: badge.rarity,
                    totalBadges: badgeStore.earnedBadges.count
                )
            }
            badgeStore.dismissRecentBadge()
        }
    }
}

// MARK: - ContentView ViewModifiers

private struct ContentViewChangeHandlers: ViewModifier {
    @ObservedObject var badgeStore: BadgeStore
    @ObservedObject var store: DrinkStore
    @ObservedObject var reviewService: ReviewPromptService
    @ObservedObject var milestoneService: MilestoneCardService
    @Binding var showingBadgeToast: Bool
    @Binding var showingMilestoneCard: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: badgeStore.recentlyUnlocked) { _, newBadge in
                if newBadge != nil {
                    showingBadgeToast = true
                    HapticManager.badgeUnlocked()
                    // Review prompt is deferred to toast dismiss so it doesn't
                    // collide with the celebration UI.
                }
            }
            .onChange(of: store.entries.count) { oldCount, newCount in
                if newCount > oldCount {
                    reviewService.checkForReviewPrompt(
                        totalDrinks: newCount,
                        currentStreak: store.streakDays
                    )
                }
            }
            .onChange(of: store.streakDays) { oldStreak, newStreak in
                if newStreak > oldStreak {
                    reviewService.checkForReviewAfterStreak(streakDays: newStreak)
                }
            }
            .onChange(of: milestoneService.pendingCard) { _, newCard in
                if newCard != nil {
                    showingMilestoneCard = true
                }
            }
    }
}

private struct ContentViewSheets: ViewModifier {
    @ObservedObject var milestoneService: MilestoneCardService
    @ObservedObject var badgeStore: BadgeStore
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var reviewService: ReviewPromptService
    @Binding var showingMilestoneCard: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingWhatsNew: Bool
    @Binding var showingPaywallFromDeepLink: Bool
    @Binding var showingTodayRecap: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingMilestoneCard) {
                if let card = milestoneService.pendingCard {
                    MilestoneCardPreviewSheet(card: card)
                        .onDisappear {
                            milestoneService.dismissCard()
                            reviewService.checkForReviewAfterPositiveMoment()
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
            .sheet(isPresented: $showingPaywallFromDeepLink) {
                PaywallView()
            }
            .sheet(isPresented: $showingTodayRecap) {
                TodayRecapSheet()
                    .onDisappear {
                        reviewService.checkForReviewAfterPositiveMoment()
                    }
            }
    }
}

private struct ContentViewDeepLinks: ViewModifier {
    @ObservedObject var deepLinkHandler: DeepLinkHandler
    @Binding var selectedTab: ContentView.RootTab
    @Binding var showingAddDrink: Bool
    @Binding var showingPaywallFromDeepLink: Bool
    @Binding var showingTodayRecap: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: deepLinkHandler.shouldNavigateToAddFriend) { _, shouldNavigate in
                if shouldNavigate {
                    selectedTab = .social
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
                    selectedTab = .stats
                    deepLinkHandler.clearPendingNavigation()
                }
            }
            .onChange(of: deepLinkHandler.shouldNavigateToBadges) { _, shouldNavigate in
                if shouldNavigate {
                    selectedTab = .badges
                    deepLinkHandler.clearPendingNavigation()
                }
            }
            .onChange(of: deepLinkHandler.shouldNavigateToStateCans) { _, shouldNavigate in
                if shouldNavigate {
                    selectedTab = .cans
                    deepLinkHandler.clearPendingNavigation()
                }
            }
            .onChange(of: deepLinkHandler.shouldShowPaywall) { _, shouldShow in
                if shouldShow {
                    showingPaywallFromDeepLink = true
                    deepLinkHandler.clearPendingNavigation()
                }
            }
            .onChange(of: deepLinkHandler.shouldShowTodayRecap) { _, shouldShow in
                if shouldShow {
                    selectedTab = .today
                    showingTodayRecap = true
                    deepLinkHandler.clearPendingNavigation()
                }
            }
            .onChange(of: deepLinkHandler.shouldNavigateToGlobalFeed) { _, shouldNavigate in
                if shouldNavigate {
                    // SocialMainView finishes the routing (Feed section, Global
                    // scope) and clears the flag once it has.
                    selectedTab = .social
                }
            }
    }
}

#if DEBUG
#Preview {
    ContentView().withPreviewEnvironment()
}
#endif
