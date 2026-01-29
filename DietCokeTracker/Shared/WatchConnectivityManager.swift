import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isReachable = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send Data to Watch

    func sendSubscriptionStatus(_ isPremium: Bool) {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated")
            return
        }

        let context: [String: Any] = [
            "isPremium": isPremium,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Use application context for guaranteed delivery (even if Watch app isn't running)
        do {
            try session.updateApplicationContext(context)
            print("[WatchConnectivity] Sent subscription status: \(isPremium)")
        } catch {
            print("[WatchConnectivity] Failed to send context: \(error)")
        }

        // Also try immediate message if Watch is reachable
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { error in
                print("[WatchConnectivity] Message send error: \(error)")
            }
        }
    }

    func requestSubscriptionStatusFromPhone() {
        // This is for the Watch to request status - not used on iPhone side
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
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] Session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchConnectivity] Session deactivated")
        // Reactivate for switching between watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
        }
    }

    // Handle messages from Watch requesting status
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["requestSubscriptionStatus"] != nil {
            Task { @MainActor in
                let isPremium = SubscriptionStatusManager.isPremium()
                self.sendSubscriptionStatus(isPremium)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["requestSubscriptionStatus"] != nil {
            Task { @MainActor in
                let isPremium = SubscriptionStatusManager.isPremium()
                replyHandler(["isPremium": isPremium])
            }
        }
    }
}
