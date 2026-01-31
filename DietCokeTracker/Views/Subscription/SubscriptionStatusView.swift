import SwiftUI

struct SubscriptionStatusView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showingPaywall = false

    var body: some View {
        List {
            if purchaseService.isPremium {
                // Active subscription
                Section {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.dietCokeRed)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FridgeCig Pro")
                                .font(.headline)
                            Text("Your subscription is active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Current Plan")
                }

                Section {
                    FeatureStatusRow(title: "Home Screen Widgets", isUnlocked: true)
                    FeatureStatusRow(title: "Lock Screen Widgets", isUnlocked: true)
                    FeatureStatusRow(title: "Apple Watch App", isUnlocked: true)
                } header: {
                    Text("Premium Features")
                }

                Section {
                    Button("Manage Subscription") {
                        openSubscriptionSettings()
                    }
                } footer: {
                    Text("Manage your subscription in Settings > Apple ID > Subscriptions")
                }
            } else {
                // Not subscribed
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "crown")
                            .font(.system(size: 50))
                            .foregroundColor(.dietCokeSilver)

                        Text("Unlock FridgeCig Pro")
                            .font(.title2.bold())

                        Text("Get access to widgets and Apple Watch app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            showingPaywall = true
                        } label: {
                            Text("View Plans")
                        }
                        .buttonStyle(.dietCokePrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                Section {
                    FeatureStatusRow(title: "Home Screen Widgets", isUnlocked: false)
                    FeatureStatusRow(title: "Lock Screen Widgets", isUnlocked: false)
                    FeatureStatusRow(title: "Apple Watch App", isUnlocked: false)
                } header: {
                    Text("Premium Features")
                }

                Section {
                    Button("Restore Purchases") {
                        Task {
                            try? await purchaseService.restorePurchases()
                        }
                    }

                    Button("Refresh Status") {
                        Task {
                            await purchaseService.checkSubscriptionStatus()
                        }
                    }
                } footer: {
                    Text("If you've previously subscribed, tap Restore Purchases. Tap Refresh Status to check again.")
                }

                #if DEBUG
                Section {
                    Text(purchaseService.debugInfo.isEmpty ? "No debug info yet" : purchaseService.debugInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Debug Info")
                }
                #endif
            }
        }
        .navigationTitle("Subscription")
        .refreshable {
            await purchaseService.checkSubscriptionStatus()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Feature Status Row

private struct FeatureStatusRow: View {
    let title: String
    let isUnlocked: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(isUnlocked ? .green : .secondary)
        }
    }
}

#Preview("Subscribed") {
    NavigationStack {
        SubscriptionStatusView()
            .environmentObject(PurchaseService.shared)
    }
}
