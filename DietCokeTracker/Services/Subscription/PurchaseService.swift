import Foundation
import RevenueCat

@MainActor
class PurchaseService: NSObject, ObservableObject {
    static let shared = PurchaseService()

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var isPurchasing = false
    @Published var error: Error?

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
        } catch {
            print("Failed to load offerings: \(error)")
            self.error = error
        }
    }

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(from: customerInfo)
        } catch {
            print("Failed to check subscription status: \(error)")
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
        let isActive = customerInfo.entitlements["pro"]?.isActive == true
        isPremium = isActive
        SubscriptionStatusManager.setIsPremium(isActive)
    }
}

extension PurchaseService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updatePremiumStatus(from: customerInfo)
        }
    }
}
