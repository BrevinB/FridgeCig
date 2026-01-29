import Foundation
import Combine
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isPremium = false
    @Published var isReachable = false

    private var session: WCSession?

    override init() {
        super.init()
        // Load cached status first
        isPremium = UserDefaults.standard.bool(forKey: "isPremiumSubscriber")

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Request Status from iPhone

    func requestSubscriptionStatus() {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated")
            return
        }

        // Check application context first (this contains the last sent data)
        if let isPremiumValue = session.receivedApplicationContext["isPremium"] as? Bool {
            updatePremiumStatus(isPremiumValue)
        }

        // Request fresh status if reachable
        if session.isReachable {
            session.sendMessage(["requestSubscriptionStatus": true], replyHandler: { response in
                if let isPremium = response["isPremium"] as? Bool {
                    Task { @MainActor in
                        self.updatePremiumStatus(isPremium)
                    }
                }
            }, errorHandler: { error in
                print("[WatchConnectivity] Request failed: \(error)")
            })
        }
    }

    private func updatePremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        // Cache locally
        UserDefaults.standard.set(isPremium, forKey: "isPremiumSubscriber")
        print("[WatchConnectivity] Updated premium status: \(isPremium)")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("[WatchConnectivity] Activation failed: \(error)")
            } else {
                print("[WatchConnectivity] Activated with state: \(activationState.rawValue)")
                // Request status after activation
                self.requestSubscriptionStatus()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
            if session.isReachable {
                self.requestSubscriptionStatus()
            }
        }
    }

    // Receive application context updates from iPhone
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let isPremium = applicationContext["isPremium"] as? Bool {
            Task { @MainActor in
                self.updatePremiumStatus(isPremium)
            }
        }
    }

    // Receive immediate messages from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let isPremium = message["isPremium"] as? Bool {
            Task { @MainActor in
                self.updatePremiumStatus(isPremium)
            }
        }
    }
}
