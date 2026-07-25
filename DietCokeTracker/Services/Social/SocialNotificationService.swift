import Foundation
import CloudKit
import os

/// The social inbox: reactions, comments, friend activity, and nudges.
///
/// Every entry is written by the person who performed the action and addressed
/// to the person it happened to, which means one CloudKit subscription on
/// `recipientID` covers every social push — and each push can name the actor
/// instead of saying "someone did something".
///
/// Read state is deliberately local (UserDefaults). Marking something read is a
/// per-device UI concern and isn't worth a public-database write per glance.
@MainActor
final class SocialNotificationService: ObservableObject {
    @Published private(set) var notifications: [SocialNotification] = []
    @Published private(set) var unreadCount = 0
    @Published private(set) var isLoading = false

    private let cloudKitManager: CloudKitManager
    private var currentUserID: String?
    private var currentProfile: UserProfile?
    private var blockedUserIDs: Set<String> = []
    private var readIDs: Set<String> = []
    private var nudgeTimestamps: [String: Date] = [:]

    private var isCurrentlyFetching = false
    private var lastFetchDate: Date?
    private let freshnessWindow: TimeInterval = 30
    private let fetchLimit = 100

    /// A nudge is a tap on the shoulder, not a megaphone. One per friend per
    /// cooldown window.
    static let nudgeCooldown: TimeInterval = 60 * 60 * 3

    private let readIDsKey = "SocialNotificationReadIDs"
    private let nudgeTimestampsKey = "SocialNudgeTimestamps"

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
        self.readIDs = Self.loadReadIDs(key: readIDsKey)
        self.nudgeTimestamps = Self.loadNudgeTimestamps(key: nudgeTimestampsKey)
    }

    // MARK: - Configure

    func configure(profile: UserProfile?) {
        let changedUser = currentProfile?.userIDString != profile?.userIDString
        currentProfile = profile
        currentUserID = profile?.userIDString

        if changedUser {
            notifications = []
            unreadCount = 0
            lastFetchDate = nil
        }
    }

    func configure(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
        notifications.removeAll { blockedUserIDs.contains($0.actorID) }
        recalculateUnread()
    }

    // MARK: - Fetch

    func refresh(force: Bool = false) async {
        guard let userID = currentUserID else { return }

        if !force,
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < freshnessWindow {
            return
        }

        guard !isCurrentlyFetching else { return }
        isCurrentlyFetching = true
        isLoading = true
        defer {
            isLoading = false
            isCurrentlyFetching = false
        }

        do {
            let cutoff = Date().addingTimeInterval(-SocialNotification.retentionWindow)
            let predicate = NSPredicate(
                format: "recipientID == %@ AND createdAt > %@",
                userID,
                cutoff as NSDate
            )
            let sort = NSSortDescriptor(key: "createdAt", ascending: false)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: SocialNotification.recordType,
                predicate: predicate,
                sortDescriptors: [sort],
                limit: fetchLimit
            )

            var fetched: [SocialNotification] = []
            for record in records {
                guard let notification = SocialNotification(from: record),
                      notification.actorID != userID,
                      !blockedUserIDs.contains(notification.actorID) else { continue }
                fetched.append(notification)
            }

            notifications = fetched.sorted { $0.createdAt > $1.createdAt }
            recalculateUnread()
            lastFetchDate = Date()
        } catch {
            AppLogger.notifications.error("Failed to load social inbox: \(error.localizedDescription)")
        }
    }

    // MARK: - Read State

    func isUnread(_ notification: SocialNotification) -> Bool {
        !readIDs.contains(notification.id.uuidString)
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        for notification in notifications {
            readIDs.insert(notification.id.uuidString)
        }
        persistReadIDs()
        unreadCount = 0
    }

    func markRead(_ notification: SocialNotification) {
        guard isUnread(notification) else { return }
        readIDs.insert(notification.id.uuidString)
        persistReadIDs()
        recalculateUnread()
    }

    private func recalculateUnread() {
        unreadCount = notifications.reduce(into: 0) { total, notification in
            if !readIDs.contains(notification.id.uuidString) { total += 1 }
        }
    }

    private func persistReadIDs() {
        // Bound the set so it can't grow without limit; anything dropped is
        // older than the retention window and will never be fetched again.
        // Skip the trim before the first fetch, when there's nothing to
        // compare against.
        if !notifications.isEmpty {
            readIDs = readIDs.intersection(Set(notifications.map { $0.id.uuidString }))
        }
        UserDefaults.standard.set(Array(readIDs), forKey: readIDsKey)
    }

    private static func loadReadIDs(key: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    // MARK: - Send

    /// Writes an inbox entry for `recipientID`. No-ops when the recipient is
    /// the actor or when there's no signed-in profile to attribute it to.
    func send(
        kind: SocialNotificationKind,
        to recipientID: String,
        activityID: UUID? = nil,
        detail: String? = nil
    ) async {
        guard let profile = currentProfile else { return }
        guard recipientID != profile.userIDString, !recipientID.isEmpty else { return }

        let notification = SocialNotification(
            recipientID: recipientID,
            actorID: profile.userIDString,
            actorName: profile.displayName,
            actorPhotoID: profile.profilePhotoID,
            actorEmoji: profile.profileEmoji,
            kind: kind,
            activityID: activityID,
            // Comment bodies get trimmed for the push preview.
            detail: kind == .comment ? detail.map { String($0.prefix(80)) } : detail
        )

        do {
            try await cloudKitManager.saveToPublic(notification.toCKRecord())
            AppLogger.notifications.info("Sent \(kind.rawValue) notification to \(recipientID)")
        } catch {
            AppLogger.notifications.error("Failed to send \(kind.rawValue) notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Nudges

    func canNudge(_ friendID: String) -> Bool {
        nudgeCooldownRemaining(for: friendID) == nil
    }

    /// Time left before `friendID` can be nudged again, or nil if they can be
    /// nudged now.
    func nudgeCooldownRemaining(for friendID: String) -> TimeInterval? {
        guard let last = nudgeTimestamps[friendID] else { return nil }
        let elapsed = Date().timeIntervalSince(last)
        guard elapsed < Self.nudgeCooldown else { return nil }
        return Self.nudgeCooldown - elapsed
    }

    /// Sends a "where's your Diet Coke?" poke. Returns false when the friend is
    /// still in their cooldown window.
    @discardableResult
    func nudge(_ friend: UserProfile, message: String? = nil) async -> Bool {
        guard currentProfile != nil else { return false }
        guard canNudge(friend.userIDString) else { return false }

        // Reserve the slot before the network call so a double-tap can't send
        // two nudges.
        nudgeTimestamps[friend.userIDString] = Date()
        persistNudgeTimestamps()

        let detail = message ?? Self.randomNudgeMessage()
        await send(kind: .nudge, to: friend.userIDString, detail: detail)
        return true
    }

    private static func randomNudgeMessage() -> String {
        let options = [
            "nudged you — time for a fridge cig 🥤",
            "says your streak isn't going to log itself 🥤",
            "is cracking one open. Join them? 🥤",
            "wants to know where your Diet Coke is 🥤",
            "challenged you to a fridge cig 🥤"
        ]
        return options.randomElement() ?? "nudged you 🥤"
    }

    private func persistNudgeTimestamps() {
        // Drop expired entries so the dictionary stays small.
        let cutoff = Date().addingTimeInterval(-Self.nudgeCooldown)
        nudgeTimestamps = nudgeTimestamps.filter { $0.value > cutoff }
        let encoded = nudgeTimestamps.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(encoded, forKey: nudgeTimestampsKey)
    }

    private static func loadNudgeTimestamps(key: String) -> [String: Date] {
        guard let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] else {
            return [:]
        }
        return raw.mapValues { Date(timeIntervalSince1970: $0) }
    }

    // MARK: - Data Management

    func clearAllData() {
        notifications = []
        unreadCount = 0
        readIDs = []
        nudgeTimestamps = [:]
        lastFetchDate = nil
        UserDefaults.standard.removeObject(forKey: readIDsKey)
        UserDefaults.standard.removeObject(forKey: nudgeTimestampsKey)
    }

    // MARK: - Debug

    #if DEBUG
    func addTestNotifications() {
        let actors = [
            ("DCFan", "🥤"),
            ("CokeZeroKing", "👑"),
            ("SodaQueen", "💅"),
            ("FountainFinder", "⛲️")
        ]

        notifications = [
            SocialNotification(
                recipientID: currentUserID ?? "me",
                actorID: "test1",
                actorName: actors[0].0,
                actorEmoji: actors[0].1,
                kind: .reaction,
                detail: ReactionEmoji.fire.rawValue,
                createdAt: Date().addingTimeInterval(-300)
            ),
            SocialNotification(
                recipientID: currentUserID ?? "me",
                actorID: "test2",
                actorName: actors[1].0,
                actorEmoji: actors[1].1,
                kind: .comment,
                detail: "that fountain ratio is immaculate",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            SocialNotification(
                recipientID: currentUserID ?? "me",
                actorID: "test3",
                actorName: actors[2].0,
                actorEmoji: actors[2].1,
                kind: .nudge,
                detail: "is cracking one open. Join them? 🥤",
                createdAt: Date().addingTimeInterval(-5400)
            ),
            SocialNotification(
                recipientID: currentUserID ?? "me",
                actorID: "test4",
                actorName: actors[3].0,
                actorEmoji: actors[3].1,
                kind: .friendRequest,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
        recalculateUnread()
    }
    #endif
}
