import Foundation
import CloudKit
import Combine
import os

/// Loads and posts replies on feed activities.
///
/// Comments live in their own `ActivityComment` record type rather than on the
/// activity itself: a popular post would otherwise turn into a write-contention
/// hotspot, and a comment thread has no useful size bound.
@MainActor
final class CommentService: ObservableObject {
    /// Full threads, keyed by activity. Populated on demand when a thread opens.
    @Published private(set) var threads: [UUID: [ActivityComment]] = [:]
    /// Counts for feed rows — cheap to batch-fetch for a whole screen of posts.
    @Published private(set) var counts: [UUID: Int] = [:]
    /// Most recent reply per activity, surfaced as a one-line preview in the
    /// feed. Comes free with the count query.
    @Published private(set) var latest: [UUID: ActivityComment] = [:]
    @Published private(set) var loadingActivityIDs: Set<UUID> = []
    @Published var isPosting = false

    /// Set at launch so commenting on a friend's post lands in their inbox.
    weak var socialNotifications: SocialNotificationService?

    private let cloudKitManager: CloudKitManager
    private var currentUserID: String?
    private var blockedUserIDs: Set<String> = []
    private var recordIDs: [UUID: CKRecord.ID] = [:]
    private var lastLoadDates: [UUID: Date] = [:]

    private let freshnessWindow: TimeInterval = 20
    private let threadLimit = 100
    private let countBatchSize = 40

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    // MARK: - Configure

    func configure(currentUserID: String?) {
        self.currentUserID = currentUserID
    }

    func configure(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
        for (activityID, comments) in threads {
            let filtered = comments.filter { !blockedUserIDs.contains($0.authorID) }
            threads[activityID] = filtered
            counts[activityID] = filtered.count
        }
        latest = latest.filter { !blockedUserIDs.contains($0.value.authorID) }
    }

    // MARK: - Reads

    func comments(for activityID: UUID) -> [ActivityComment] {
        threads[activityID] ?? []
    }

    func count(for activityID: UUID) -> Int {
        counts[activityID] ?? threads[activityID]?.count ?? 0
    }

    /// The newest reply, preferring a fully loaded thread over the batch query's
    /// best-effort result.
    func latestComment(for activityID: UUID) -> ActivityComment? {
        threads[activityID]?.last ?? latest[activityID]
    }

    func isLoading(_ activityID: UUID) -> Bool {
        loadingActivityIDs.contains(activityID)
    }

    func canDelete(_ comment: ActivityComment) -> Bool {
        comment.authorID == currentUserID
    }

    // MARK: - Load

    func loadThread(for activityID: UUID, force: Bool = false) async {
        if !force,
           let lastLoad = lastLoadDates[activityID],
           Date().timeIntervalSince(lastLoad) < freshnessWindow {
            return
        }

        guard !loadingActivityIDs.contains(activityID) else { return }
        loadingActivityIDs.insert(activityID)
        defer { loadingActivityIDs.remove(activityID) }

        do {
            let predicate = NSPredicate(format: "activityID == %@", activityID.uuidString)
            let sort = NSSortDescriptor(key: "createdAt", ascending: true)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityComment.recordType,
                predicate: predicate,
                sortDescriptors: [sort],
                limit: threadLimit
            )

            var fetched: [ActivityComment] = []
            for record in records {
                guard let comment = ActivityComment(from: record),
                      !blockedUserIDs.contains(comment.authorID) else { continue }
                recordIDs[comment.id] = record.recordID
                fetched.append(comment)
            }

            // Keep any comment posted locally that CloudKit hasn't indexed yet.
            let fetchedIDs = Set(fetched.map { $0.id })
            let pending = (threads[activityID] ?? []).filter { !fetchedIDs.contains($0.id) }

            let merged = (fetched + pending).sorted { $0.createdAt < $1.createdAt }
            threads[activityID] = merged
            counts[activityID] = merged.count
            lastLoadDates[activityID] = Date()
        } catch {
            AppLogger.activity.error("Failed to load comments for \(activityID.uuidString): \(error.localizedDescription)")
        }
    }

    /// Batch-fetches comment counts for a screenful of posts in one query, so
    /// the feed can show reply counts without a request per row.
    func loadCounts(for activityIDs: [UUID]) async {
        let ids = Array(Set(activityIDs)).prefix(countBatchSize)
        guard !ids.isEmpty else { return }

        let idStrings = ids.map { $0.uuidString }
        do {
            let predicate = NSPredicate(format: "activityID IN %@", idStrings)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityComment.recordType,
                predicate: predicate,
                limit: threadLimit * 2
            )

            var tally: [UUID: Int] = [:]
            var newest: [UUID: ActivityComment] = [:]
            for id in ids { tally[id] = 0 }
            for record in records {
                guard let comment = ActivityComment(from: record),
                      !blockedUserIDs.contains(comment.authorID) else { continue }
                tally[comment.activityID, default: 0] += 1
                if let current = newest[comment.activityID], current.createdAt >= comment.createdAt {
                    continue
                }
                newest[comment.activityID] = comment
            }

            for (activityID, total) in tally {
                // A thread we've already opened is more authoritative than a
                // capped batch query.
                if let loaded = threads[activityID], loaded.count > total { continue }
                counts[activityID] = total
                if total == 0 {
                    // Everything was deleted remotely — drop the stale preview
                    // so the feed doesn't show a comment it just counted as zero.
                    latest.removeValue(forKey: activityID)
                }
            }
            for (activityID, comment) in newest {
                latest[activityID] = comment
            }
        } catch {
            AppLogger.activity.error("Failed to load comment counts: \(error.localizedDescription)")
        }
    }

    // MARK: - Post

    /// Posts a reply and returns it, or nil when the text is empty or the save
    /// fails. The comment appears locally immediately and is rolled back if
    /// CloudKit rejects it.
    @discardableResult
    func post(
        text rawText: String,
        on activity: ActivityItem,
        author: UserProfile
    ) async -> ActivityComment? {
        guard let text = ActivityComment.sanitize(rawText) else { return nil }

        let comment = ActivityComment(
            activityID: activity.id,
            authorID: author.userIDString,
            authorName: author.displayName,
            authorPhotoID: author.profilePhotoID,
            authorEmoji: author.profileEmoji,
            text: text
        )

        isPosting = true
        defer { isPosting = false }

        let previousLatest = latest[activity.id]
        threads[activity.id, default: []].append(comment)
        counts[activity.id] = (counts[activity.id] ?? 0) + 1
        latest[activity.id] = comment

        do {
            let record = comment.toCKRecord()
            try await cloudKitManager.saveToPublic(record)
            recordIDs[comment.id] = record.recordID
        } catch {
            AppLogger.activity.error("Failed to post comment: \(error.localizedDescription)")
            threads[activity.id]?.removeAll { $0.id == comment.id }
            counts[activity.id] = max(0, (counts[activity.id] ?? 1) - 1)
            latest[activity.id] = previousLatest
            return nil
        }

        if activity.userID != author.userIDString {
            await socialNotifications?.send(
                kind: .comment,
                to: activity.userID,
                activityID: activity.id,
                detail: text
            )
        }

        return comment
    }

    // MARK: - Delete

    func delete(_ comment: ActivityComment) async {
        guard canDelete(comment) else { return }

        let previous = threads[comment.activityID] ?? []
        let previousLatest = latest[comment.activityID]
        threads[comment.activityID]?.removeAll { $0.id == comment.id }
        counts[comment.activityID] = max(0, (counts[comment.activityID] ?? 1) - 1)
        if previousLatest?.id == comment.id {
            latest[comment.activityID] = threads[comment.activityID]?.last
        }

        do {
            let recordID: CKRecord.ID
            if let cached = recordIDs[comment.id] {
                recordID = cached
            } else {
                let predicate = NSPredicate(format: "commentID == %@", comment.id.uuidString)
                let records = try await cloudKitManager.fetchFromPublic(
                    recordType: ActivityComment.recordType,
                    predicate: predicate,
                    limit: 1
                )
                guard let found = records.first else { return }
                recordID = found.recordID
            }

            try await cloudKitManager.deleteFromPublic(recordID: recordID)
            recordIDs.removeValue(forKey: comment.id)
        } catch {
            AppLogger.activity.error("Failed to delete comment: \(error.localizedDescription)")
            threads[comment.activityID] = previous
            counts[comment.activityID] = previous.count
            latest[comment.activityID] = previousLatest
        }
    }

    /// Removes a whole thread — used when its parent activity is deleted.
    func deleteThread(for activityID: UUID) async {
        threads.removeValue(forKey: activityID)
        counts.removeValue(forKey: activityID)
        latest.removeValue(forKey: activityID)
        lastLoadDates.removeValue(forKey: activityID)

        do {
            let predicate = NSPredicate(format: "activityID == %@", activityID.uuidString)
            let records = try await cloudKitManager.fetchFromPublic(
                recordType: ActivityComment.recordType,
                predicate: predicate,
                limit: threadLimit
            )
            guard !records.isEmpty else { return }
            try await cloudKitManager.batchDeleteFromPublic(records.map { $0.recordID })
        } catch {
            AppLogger.activity.error("Failed to delete comment thread: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Management

    func clearAllData() {
        threads = [:]
        counts = [:]
        latest = [:]
        recordIDs = [:]
        lastLoadDates = [:]
        loadingActivityIDs = []
    }
}
