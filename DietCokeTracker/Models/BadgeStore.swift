import Foundation
import SwiftUI

@MainActor
class BadgeStore: ObservableObject {
    @Published private(set) var unlockedBadges: [String: Date] = [:]
    @Published var recentlyUnlocked: Badge?

    private let saveKey = "UnlockedBadges"

    init() {
        loadBadges()
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
