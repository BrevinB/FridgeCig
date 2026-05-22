import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showingAddDrink: Bool
    @State private var showingSettings = false
    @State private var showingCatalog = false
    @State private var celebrationActive = false
    @State private var showDrinkUpsell = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        TodaySummaryCard()
                        TodayDrinksSection()
                        HomeActivityFeedSection()

                        if showDrinkUpsell && !purchaseService.isPremium {
                            UpsellBanner.drinkTrigger(
                                onTap: { showingPaywall = true },
                                onDismiss: {
                                    withAnimation { showDrinkUpsell = false }
                                    preferences.markDrinkUpsellShown()
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                if celebrationActive {
                    FizzBurstView(isActive: $celebrationActive)
                        .ignoresSafeArea()
                }

                floatingAddButton
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
                        showingCatalog = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17))
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingCatalog) { DrinkCatalogView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .onChange(of: store.todayCount) { oldValue, newValue in
                if newValue > oldValue {
                    celebrationActive = true
                    HapticManager.drinkAdded()
                }
            }
            .onChange(of: store.allTimeCount) { _, newCount in
                if !purchaseService.isPremium && preferences.shouldShowDrinkUpsell(drinkCount: newCount) {
                    withAnimation(.easeInOut.delay(0.5)) {
                        showDrinkUpsell = true
                    }
                }
            }
        }
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showingAddDrink = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(preferences.defaultBrand.gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: preferences.defaultBrand.color.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

#if DEBUG
private struct HomeViewPreviewWrapper: View {
    @State private var showingAddDrink = false
    var body: some View { HomeView(showingAddDrink: $showingAddDrink) }
}

#Preview { HomeViewPreviewWrapper().withPreviewEnvironment() }
#endif
