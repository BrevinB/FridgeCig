import Foundation
import WatchConnectivity
import os

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
            AppLogger.watch.debug("Session not activated")
            return
        }

        let context: [String: Any] = [
            "isPremium": isPremium,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Use application context for guaranteed delivery (even if Watch app isn't running)
        do {
            try session.updateApplicationContext(context)
            AppLogger.watch.debug("Sent subscription status: \(isPremium)")
        } catch {
            AppLogger.watch.error("Failed to send context: \(error.localizedDescription)")
        }

        // Also try immediate message if Watch is reachable
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { error in
                AppLogger.watch.error("Message send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Send Drink Entries to Watch

    func syncEntriesToWatch(_ entries: [DrinkEntry]) {
        guard let session = session, session.activationState == .activated else {
            AppLogger.watch.debug("Session not activated for entry sync")
            return
        }

        // Encode entries to data
        guard let entriesData = try? JSONEncoder().encode(entries) else {
            AppLogger.watch.error("Failed to encode entries")
            return
        }

        // Use transferUserInfo for reliable delivery of entry data
        // This is better for larger data that needs to arrive reliably
        let userInfo: [String: Any] = [
            "entriesData": entriesData,
            "syncTimestamp": Date().timeIntervalSince1970
        ]

        session.transferUserInfo(userInfo)
        AppLogger.watch.debug("Transferred \(entries.count) entries to Watch")

        // Also send via message for immediate update if reachable
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                AppLogger.watch.debug("Entry sync message error: \(error)")
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
                AppLogger.watch.error("Activation failed: \(error.localizedDescription)")
            } else {
                AppLogger.watch.debug("Activated with state: \(activationState.rawValue)")
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        AppLogger.watch.debug("Session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        AppLogger.watch.debug("Session deactivated")
        // Reactivate for switching between watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            AppLogger.watch.debug("Reachability changed: \(session.isReachable)")
        }
    }

    // Handle messages from Watch requesting status or sending entries
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["requestSubscriptionStatus"] != nil {
            Task { @MainActor in
                let isPremium = SubscriptionStatusManager.isPremium()
                self.sendSubscriptionStatus(isPremium)
            }
        }

        // Handle request for full data sync
        if message["requestDataSync"] != nil {
            Task { @MainActor in
                let entries = SharedDataManager.getEntries()
                self.syncEntriesToWatch(entries)
            }
        }

        // Handle new entry from Watch
        if let entryData = message["newEntry"] as? Data {
            handleNewEntryFromWatch(entryData)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["requestSubscriptionStatus"] != nil {
            Task { @MainActor in
                let isPremium = SubscriptionStatusManager.isPremium()
                replyHandler(["isPremium": isPremium])
            }
        }

        // Handle request for entries with reply
        if message["requestEntries"] != nil {
            Task { @MainActor in
                let entries = SharedDataManager.getEntries()
                if let data = try? JSONEncoder().encode(entries) {
                    replyHandler(["entriesData": data])
                } else {
                    replyHandler(["error": "Failed to encode entries"])
                }
            }
        }
    }

    // Handle userInfo transfers from Watch
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let entryData = userInfo["newEntry"] as? Data {
            handleNewEntryFromWatch(entryData)
        }
    }

    // MARK: - Handle Entries from Watch

    private nonisolated func handleNewEntryFromWatch(_ entryData: Data) {
        guard let entry = try? JSONDecoder().decode(DrinkEntry.self, from: entryData) else {
            AppLogger.watch.error("Failed to decode entry from Watch")
            return
        }

        AppLogger.watch.debug("Received new entry from Watch: \(entry.type.displayName)")

        // Post notification to merge entry into DrinkStore
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .watchDidAddEntry,
                object: nil,
                userInfo: ["entry": entry]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchDidAddEntry = Notification.Name("watchDidAddEntry")
}
