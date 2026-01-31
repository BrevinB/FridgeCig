import Foundation
import RevenueCat

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
            print("[PurchaseService] Loaded offerings: \(offerings?.current?.identifier ?? "none")")
        } catch {
            print("[PurchaseService] Failed to load offerings: \(error)")
            self.error = error
        }
    }

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(from: customerInfo)
        } catch {
            print("[PurchaseService] Failed to check subscription status: \(error)")
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
        print("[PurchaseService] All entitlements: \(allEntitlements.keys.joined(separator: ", "))")

        for (key, entitlement) in allEntitlements {
            print("[PurchaseService] Entitlement '\(key)': isActive=\(entitlement.isActive), productId=\(entitlement.productIdentifier)")
        }

        // Log active subscriptions
        let activeSubscriptions = customerInfo.activeSubscriptions
        print("[PurchaseService] Active subscriptions: \(activeSubscriptions.joined(separator: ", "))")

        // Check for premium entitlement (try multiple common identifiers)
        var isActive = false

        // Try the configured identifier first
        if let entitlement = customerInfo.entitlements[Self.entitlementIdentifier] {
            isActive = entitlement.isActive
            print("[PurchaseService] Found entitlement '\(Self.entitlementIdentifier)': isActive=\(isActive)")
        }

        // If not found, check for any active entitlement (fallback)
        if !isActive && !allEntitlements.isEmpty {
            for (key, entitlement) in allEntitlements {
                if entitlement.isActive {
                    isActive = true
                    print("[PurchaseService] Found active entitlement '\(key)' (fallback)")
                    break
                }
            }
        }

        // Also check if there are any active subscriptions even without entitlements
        // This can happen if entitlements aren't configured correctly in RevenueCat
        if !isActive && !activeSubscriptions.isEmpty {
            isActive = true
            print("[PurchaseService] User has active subscriptions but no entitlements configured - treating as premium")
        }

        // Build debug info
        debugInfo = """
        Entitlements: \(allEntitlements.keys.joined(separator: ", ").isEmpty ? "none" : allEntitlements.keys.joined(separator: ", "))
        Active Subscriptions: \(activeSubscriptions.joined(separator: ", ").isEmpty ? "none" : activeSubscriptions.joined(separator: ", "))
        isPremium: \(isActive)
        """

        print("[PurchaseService] Final isPremium: \(isActive)")
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
