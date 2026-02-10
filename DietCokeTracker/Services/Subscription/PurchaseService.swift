import Foundation
import RevenueCat
import os

@MainActor
class PurchaseService: NSObject, ObservableObject {
    static let shared = PurchaseService()

    // The entitlement identifier configured in RevenueCat dashboard
    // Common values: "pro", "Pro", "premium", "Premium"
    private static let entitlementIdentifier = "pro"

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var isPurchasing = false
    @Published var error: Error?

    // Debug info
    @Published var debugInfo: String = ""

    private override init() {
        super.init()
        // Load cached status immediately
        isPremium = SubscriptionStatusManager.isPremium()
    }

    func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
    }

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
            AppLogger.purchases.debug("Loaded offerings: \(self.offerings?.current?.identifier ?? "none")")
        } catch {
            AppLogger.purchases.error("Failed to load offerings: \(error.localizedDescription)")
            self.error = error
        }
    }

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(from: customerInfo)
        } catch {
            AppLogger.purchases.error("Failed to check subscription status: \(error.localizedDescription)")
            self.error = error
        }
    }

    func purchase(_ package: Package) async throws {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await Purchases.shared.purchase(package: package)
        updatePremiumStatus(from: result.customerInfo)
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        updatePremiumStatus(from: customerInfo)
    }

    private func updatePremiumStatus(from customerInfo: CustomerInfo) {
        // Log all entitlements for debugging
        let allEntitlements = customerInfo.entitlements.all
        AppLogger.purchases.debug("All entitlements: \(allEntitlements.keys.joined(separator: ", "))")

        for (key, entitlement) in allEntitlements {
            AppLogger.purchases.debug("Entitlement '\(key)': isActive=\(entitlement.isActive), productId=\(entitlement.productIdentifier)")
        }

        // Log active subscriptions
        let activeSubscriptions = customerInfo.activeSubscriptions
        AppLogger.purchases.debug("Active subscriptions: \(activeSubscriptions.joined(separator: ", "))")

        // Check for premium entitlement (try multiple common identifiers)
        var isActive = false

        // Try the configured identifier first
        if let entitlement = customerInfo.entitlements[Self.entitlementIdentifier] {
            isActive = entitlement.isActive
            AppLogger.purchases.debug("Found entitlement '\(Self.entitlementIdentifier)': isActive=\(isActive)")
        }

        // If not found, check for any active entitlement (fallback)
        if !isActive && !allEntitlements.isEmpty {
            for (key, entitlement) in allEntitlements {
                if entitlement.isActive {
                    isActive = true
                    AppLogger.purchases.debug("Found active entitlement '\(key)' (fallback)")
                    break
                }
            }
        }

        // Also check if there are any active subscriptions even without entitlements
        // This can happen if entitlements aren't configured correctly in RevenueCat
        if !isActive && !activeSubscriptions.isEmpty {
            isActive = true
            AppLogger.purchases.debug("User has active subscriptions but no entitlements configured - treating as premium")
        }

        // Build debug info
        debugInfo = """
        Entitlements: \(allEntitlements.keys.joined(separator: ", ").isEmpty ? "none" : allEntitlements.keys.joined(separator: ", "))
        Active Subscriptions: \(activeSubscriptions.joined(separator: ", ").isEmpty ? "none" : activeSubscriptions.joined(separator: ", "))
        isPremium: \(isActive)
        """

        AppLogger.purchases.debug("Final isPremium: \(isActive)")
        isPremium = isActive
        SubscriptionStatusManager.setIsPremium(isActive)

        // Sync to Apple Watch
        WatchConnectivityManager.shared.sendSubscriptionStatus(isActive)
    }
}

extension PurchaseService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updatePremiumStatus(from: customerInfo)
        }
    }
}
