import Foundation
import SwiftUI
import CloudKit
import Combine

@MainActor
class BadgeStore: ObservableObject {
    @Published private(set) var unlockedBadges: [String: Date] = [:]
    @Published var recentlyUnlocked: Badge?
    @Published var isSyncing = false

    /// Publisher that emits when a new badge is unlocked (for activity feed integration)
    let badgeUnlocked = PassthroughSubject<Badge, Never>()

    private let saveKey = "UnlockedBadges"
    private let recordType = "BadgeData"
    private let recordIDKey = "BadgeDataRecordID"

    /// CloudKit manager for syncing (set by app)
    var cloudKitManager: CloudKitManager?
    private var cloudRecordID: CKRecord.ID?

    init() {
        loadBadges()
        loadRecordID()
    }

    // MARK: - Badge Status

    var allBadges: [Badge] {
        BadgeDefinitions.all.map { badge in
            var updatedBadge = badge
            updatedBadge.unlockedAt = unlockedBadges[badge.id]
            return updatedBadge
        }
    }

    var earnedBadges: [Badge] {
        allBadges.filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }

    var lockedBadges: [Badge] {
        allBadges.filter { !$0.isUnlocked }
    }

    var earnedCount: Int {
        unlockedBadges.count
    }

    var totalCount: Int {
        BadgeDefinitions.all.count
    }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(earnedCount) / Double(totalCount) * 100
    }

    func badge(for id: String) -> Badge? {
        var badge = BadgeDefinitions.all.first { $0.id == id }
        badge?.unlockedAt = unlockedBadges[id]
        return badge
    }

    func isUnlocked(_ badgeId: String) -> Bool {
        unlockedBadges[badgeId] != nil
    }

    // MARK: - Badge Unlocking

    func unlock(_ badgeId: String) {
        guard !isUnlocked(badgeId) else { return }

        unlockedBadges[badgeId] = Date()
        saveBadges()

        if let badge = badge(for: badgeId) {
            recentlyUnlocked = badge
            // Notify listeners (for activity feed)
            badgeUnlocked.send(badge)
        }
    }

    func unlockSpecialEdition(_ edition: SpecialEdition) {
        let badge = edition.toBadge()
        unlock(badge.id)
    }

    func dismissRecentBadge() {
        recentlyUnlocked = nil
    }

    // MARK: - Check Achievements

    func checkAchievements(entries: [DrinkEntry], streak: Int) {
        checkMilestones(count: entries.count)
        checkStreaks(streak: streak)
        checkVolume(ounces: entries.totalOunces)
        checkVariety(entries: entries)
        checkSpecialEditions(entries: entries)
    }

    private func checkMilestones(count: Int) {
        for badge in BadgeDefinitions.milestones {
            if let threshold = BadgeDefinitions.milestoneThreshold(for: badge.id),
               count >= threshold {
                unlock(badge.id)
            }
        }
    }

    private func checkStreaks(streak: Int) {
        for badge in BadgeDefinitions.streaks {
            if let threshold = BadgeDefinitions.streakThreshold(for: badge.id),
               streak >= threshold {
                unlock(badge.id)
            }
        }
    }

    private func checkVolume(ounces: Double) {
        for badge in BadgeDefinitions.volume {
            if let threshold = BadgeDefinitions.volumeThreshold(for: badge.id),
               ounces >= threshold {
                unlock(badge.id)
            }
        }
    }

    private func checkVariety(entries: [DrinkEntry]) {
        let uniqueTypes = Set(entries.map { $0.type })
        let count = uniqueTypes.count

        for badge in BadgeDefinitions.variety {
            if let threshold = BadgeDefinitions.varietyThreshold(for: badge.id),
               count >= threshold {
                unlock(badge.id)
            }
        }
    }

    private func checkSpecialEditions(entries: [DrinkEntry]) {
        let specialEditions = Set(entries.compactMap { $0.specialEdition })
        for edition in specialEditions {
            unlockSpecialEdition(edition)
        }
    }

    // MARK: - Badges by Category

    func badges(ofType type: BadgeType) -> [Badge] {
        allBadges.filter { $0.type == type }
    }

    func badges(ofRarity rarity: BadgeRarity) -> [Badge] {
        allBadges.filter { $0.rarity == rarity }
    }

    // MARK: - Persistence

    private func saveBadges() {
        do {
            let data = try JSONEncoder().encode(unlockedBadges)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save badges: \(error)")
        }

        // Sync to CloudKit
        Task {
            try? await syncToCloud()
        }
    }

    private func loadBadges() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return
        }

        do {
            unlockedBadges = try JSONDecoder().decode([String: Date].self, from: data)
        } catch {
            print("Failed to load badges: \(error)")
        }
    }

    // MARK: - CloudKit Sync

    func performSync() async {
        guard let cloudKitManager = cloudKitManager, cloudKitManager.isAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch from cloud
            let cloudBadges = try await fetchFromCloud()

            // Merge: keep all badges from both (union with newest date wins)
            var merged = unlockedBadges
            for (badgeId, cloudDate) in cloudBadges {
                if let localDate = merged[badgeId] {
                    // Keep the earlier unlock date
                    merged[badgeId] = min(localDate, cloudDate)
                } else {
                    merged[badgeId] = cloudDate
                }
            }

            // Update local if changed
            if merged != unlockedBadges {
                unlockedBadges = merged
                let data = try JSONEncoder().encode(unlockedBadges)
                UserDefaults.standard.set(data, forKey: saveKey)
            }

            // Upload merged data
            try await syncToCloud()
        } catch {
            print("Badge sync failed: \(error)")
        }
    }

    private func fetchFromCloud() async throws -> [String: Date] {
        guard let cloudKitManager = cloudKitManager else { return [:] }

        let records = try await cloudKitManager.fetchFromPrivate(recordType: recordType)
        guard let record = records.first,
              let jsonData = record["badgesJSON"] as? String,
              let data = jsonData.data(using: .utf8) else {
            return [:]
        }

        cloudRecordID = record.recordID
        saveRecordID()

        return try JSONDecoder().decode([String: Date].self, from: data)
    }

    private func syncToCloud() async throws {
        guard let cloudKitManager = cloudKitManager, cloudKitManager.isAvailable else { return }

        let jsonData = try JSONEncoder().encode(unlockedBadges)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let record: CKRecord
        if let existingID = cloudRecordID {
            record = CKRecord(recordType: recordType, recordID: existingID)
        } else {
            record = CKRecord(recordType: recordType)
        }

        record["badgesJSON"] = jsonString

        try await cloudKitManager.saveToPrivate(record)
        cloudRecordID = record.recordID
        saveRecordID()
    }

    private func loadRecordID() {
        if let recordName = UserDefaults.standard.string(forKey: recordIDKey) {
            cloudRecordID = CKRecord.ID(recordName: recordName)
        }
    }

    private func saveRecordID() {
        if let recordID = cloudRecordID {
            UserDefaults.standard.set(recordID.recordName, forKey: recordIDKey)
        }
    }

    // MARK: - Debug

    #if DEBUG
    func unlockAllBadges() {
        for badge in BadgeDefinitions.all {
            unlockedBadges[badge.id] = Date()
        }
        saveBadges()
    }

    func resetAllBadges() {
        unlockedBadges.removeAll()
        saveBadges()
    }
    #endif
}
