import Foundation
import Combine
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isPremium = false
    @Published var isReachable = false
    @Published var entriesDidUpdate = false

    private var session: WCSession?
    private let entriesKey = "DietCokeEntries"
    private let appGroupID = "group.co.brevinb.fridgecig"

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

    // MARK: - Request Data Sync from iPhone

    func requestDataSync() {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated for data sync")
            return
        }

        if session.isReachable {
            print("[WatchConnectivity] Requesting data sync from iPhone")
            session.sendMessage(["requestEntries": true], replyHandler: { response in
                if let entriesData = response["entriesData"] as? Data {
                    self.handleReceivedEntriesData(entriesData)
                }
            }, errorHandler: { error in
                print("[WatchConnectivity] Data sync request failed: \(error)")
            })
        } else {
            // Try requesting via transferUserInfo which queues for later
            session.sendMessage(["requestDataSync": true], replyHandler: nil, errorHandler: { _ in
                print("[WatchConnectivity] iPhone not reachable, sync will happen when available")
            })
        }
    }

    // MARK: - Send Entry to iPhone

    func sendEntryToPhone(_ entry: DrinkEntry) {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated for sending entry")
            return
        }

        guard let entryData = try? JSONEncoder().encode(entry) else {
            print("[WatchConnectivity] Failed to encode entry")
            return
        }

        let userInfo: [String: Any] = ["newEntry": entryData]

        // Use transferUserInfo for reliable delivery
        session.transferUserInfo(userInfo)
        print("[WatchConnectivity] Sent new entry to iPhone: \(entry.type.displayName)")

        // Also try immediate message if reachable
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                print("[WatchConnectivity] Entry send message error: \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    private func updatePremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        // Cache locally
        UserDefaults.standard.set(isPremium, forKey: "isPremiumSubscriber")
        print("[WatchConnectivity] Updated premium status: \(isPremium)")
    }

    private nonisolated func handleReceivedEntriesData(_ data: Data) {
        guard let entries = try? JSONDecoder().decode([DrinkEntry].self, from: data) else {
            print("[WatchConnectivity] Failed to decode entries from iPhone")
            return
        }

        print("[WatchConnectivity] Received \(entries.count) entries from iPhone")

        // Save to local storage
        Task { @MainActor in
            self.saveEntriesToLocalStorage(entries)
            self.entriesDidUpdate = true
        }
    }

    // MARK: - Delta Application

    private nonisolated func handleEntryAdded(_ data: Data) {
        guard let entry = try? JSONDecoder().decode(DrinkEntry.self, from: data) else { return }
        Task { @MainActor in
            var entries = self.loadEntriesFromLocalStorage()
            if !entries.contains(where: { $0.id == entry.id }) {
                entries.append(entry)
                self.saveEntriesToLocalStorage(entries)
                self.entriesDidUpdate = true
            }
        }
    }

    private nonisolated func handleEntryUpdated(_ data: Data) {
        guard let entry = try? JSONDecoder().decode(DrinkEntry.self, from: data) else { return }
        Task { @MainActor in
            var entries = self.loadEntriesFromLocalStorage()
            if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[idx] = entry
                self.saveEntriesToLocalStorage(entries)
                self.entriesDidUpdate = true
            }
        }
    }

    private nonisolated func handleEntryDeleted(_ idString: String) {
        guard let id = UUID(uuidString: idString) else { return }
        Task { @MainActor in
            var entries = self.loadEntriesFromLocalStorage()
            let before = entries.count
            entries.removeAll { $0.id == id }
            if entries.count != before {
                self.saveEntriesToLocalStorage(entries)
                self.entriesDidUpdate = true
            }
        }
    }

    private func loadEntriesFromLocalStorage() -> [DrinkEntry] {
        let data = UserDefaults(suiteName: appGroupID)?.data(forKey: entriesKey)
            ?? UserDefaults.standard.data(forKey: entriesKey)
        guard let data else { return [] }
        return (try? JSONDecoder().decode([DrinkEntry].self, from: data)) ?? []
    }

    private func saveEntriesToLocalStorage(_ entries: [DrinkEntry]) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            // Fall back to standard UserDefaults on Watch
            saveEntriesToStandardDefaults(entries)
            return
        }

        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
            print("[WatchConnectivity] Saved \(entries.count) entries to app group storage")
        }
    }

    private func saveEntriesToStandardDefaults(_ entries: [DrinkEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
            print("[WatchConnectivity] Saved \(entries.count) entries to standard defaults")
        }
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
                // Request status and data after activation
                self.requestSubscriptionStatus()
                self.requestDataSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
            if session.isReachable {
                self.requestSubscriptionStatus()
                self.requestDataSync()
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

        applyEntryPayload(message)
    }

    // Receive userInfo transfers from iPhone (reliable delivery)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("[WatchConnectivity] Received userInfo transfer")
        applyEntryPayload(userInfo)
    }

    private nonisolated func applyEntryPayload(_ payload: [String: Any]) {
        if let data = payload["newEntryFromPhone"] as? Data {
            handleEntryAdded(data)
        }
        if let data = payload["updatedEntryFromPhone"] as? Data {
            handleEntryUpdated(data)
        }
        if let id = payload["deletedEntryIDFromPhone"] as? String {
            handleEntryDeleted(id)
        }
        // Backwards-compatible full sync
        if let entriesData = payload["entriesData"] as? Data {
            handleReceivedEntriesData(entriesData)
        }
    }
}
