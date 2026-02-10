import Foundation
import SwiftUI
import CloudKit
import Combine
import os

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
        checkLifestyleBadges(entries: entries, streak: streak)
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

    private func checkLifestyleBadges(entries: [DrinkEntry], streak: Int) {
        let calendar = Calendar.current
        let now = Date()

        // Group entries by day
        let entriesByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        // Get today's entries
        let todayStart = calendar.startOfDay(for: now)
        let todayEntries = entriesByDay[todayStart] ?? []

        // MARK: - Time-based badges

        for entry in entries {
            let hour = calendar.component(.hour, from: entry.timestamp)

            // Early Bird - before 6am
            if hour < 6 {
                unlock("early_bird")
            }

            // Night Owl - after midnight (0-3am counts as night owl)
            if hour >= 0 && hour < 4 {
                unlock("night_owl")
            }

            // Lunch Break Essential - 11am-1pm
            if hour >= 11 && hour < 13 {
                unlock("lunch_break")
            }

            // Happy Hour - 4-6pm
            if hour >= 16 && hour < 18 {
                unlock("happy_hour")
            }

            // Breakfast of Champions - before 9am
            if hour < 9 {
                unlock("breakfast_of_champions")
            }

            // Dessert Drink - after 9pm
            if hour >= 21 {
                unlock("dessert_drink")
            }

            // Speedrunner - before 7am
            if hour < 7 {
                unlock("speedrunner")
            }
        }

        // MARK: - Day-based badges

        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.timestamp)

            // Monday Motivation (weekday 2 = Monday)
            if weekday == 2 {
                unlock("monday_motivation")
            }

            // Friday Feeling (weekday 6 = Friday)
            if weekday == 6 {
                unlock("friday_feeling")
            }
        }

        // Weekend Warrior - DC on both Saturday and Sunday
        let saturdays = entries.filter { calendar.component(.weekday, from: $0.timestamp) == 7 }
        let sundays = entries.filter { calendar.component(.weekday, from: $0.timestamp) == 1 }
        if !saturdays.isEmpty && !sundays.isEmpty {
            unlock("weekend_warrior")
        }

        // MARK: - Daily frequency badges

        for (_, dayEntries) in entriesByDay {
            let count = dayEntries.count

            if count >= 2 {
                // Check if any 2 are within an hour
                let sortedByTime = dayEntries.sorted { $0.timestamp < $1.timestamp }
                for i in 0..<(sortedByTime.count - 1) {
                    let diff = sortedByTime[i + 1].timestamp.timeIntervalSince(sortedByTime[i].timestamp)
                    if diff <= 3600 { // 1 hour
                        unlock("double_fisting")
                        break
                    }
                }
            }

            if count >= 3 {
                unlock("triple_threat")
            }

            if count >= 5 {
                unlock("dc_bender")
            }

            if count >= 7 {
                unlock("absolute_unit")
            }

            // No Judgement Zone - before 8am AND after 10pm same day
            let hours = dayEntries.map { calendar.component(.hour, from: $0.timestamp) }
            if hours.contains(where: { $0 < 8 }) && hours.contains(where: { $0 >= 22 }) {
                unlock("no_judgement")
            }

            // All-Nighter - morning, afternoon, and night in same day
            let hasMorning = hours.contains(where: { $0 >= 5 && $0 < 12 })
            let hasAfternoon = hours.contains(where: { $0 >= 12 && $0 < 18 })
            let hasNight = hours.contains(where: { $0 >= 18 || $0 < 5 })
            if hasMorning && hasAfternoon && hasNight {
                unlock("all_nighter")
            }
        }

        // MARK: - Streak-based lifestyle badges

        if streak >= 14 {
            unlock("main_character")
        }

        // MARK: - Total count lifestyle badges

        let totalCount = entries.count
        if totalCount >= 10 {
            unlock("sharing_is_caring")
        }
        if totalCount >= 50 {
            unlock("its_not_an_addiction")
        }
        if totalCount >= 200 {
            unlock("send_help")
        }
        if totalCount >= 500 {
            unlock("professional")
        }
        if totalCount >= 1000 {
            unlock("dc_deity")
        }

        // MARK: - Container-based badges

        let cans = entries.filter {
            $0.type == .regularCan || $0.type == .tallCan || $0.type == .miniCan
        }
        if cans.count >= 20 {
            unlock("can_collector")
        }

        let fountains = entries.filter {
            $0.type == .fountainSmall || $0.type == .fountainMedium || $0.type == .fountainLarge || $0.type == .cafeFreestyle
        }
        if fountains.count >= 10 {
            unlock("fountain_of_youth")
        }

        let largeFountains = entries.filter {
            $0.type == .fountainLarge || $0.type == .mcdonaldsLarge || $0.type == .chickfilaLarge
        }
        if largeFountains.count >= 5 {
            unlock("big_gulp_energy")
        }

        let glassBottles = entries.filter { $0.type == .glassBottle }
        if !glassBottles.isEmpty {
            unlock("fancy_pants")
        }

        let twoLiters = entries.filter { $0.type == .bottle2Liter }
        if !twoLiters.isEmpty {
            unlock("two_liter_legend")
        }

        // MARK: - Fast food badges

        let mcdonalds = entries.filter {
            $0.type == .mcdonaldsSmall || $0.type == .mcdonaldsMedium || $0.type == .mcdonaldsLarge
        }
        if mcdonalds.count >= 5 {
            unlock("mclovin_it")
        }

        let chickfila = entries.filter {
            $0.type == .chickfilaSmall || $0.type == .chickfilaMedium || $0.type == .chickfilaLarge
        }
        if chickfila.count >= 5 {
            unlock("chick_fil_a_tier")
        }

        // MARK: - Caffeine-free badges

        let caffeineFree = entries.filter { $0.brand.isCaffeineFree }
        if !caffeineFree.isEmpty {
            unlock("plot_twist")
        }
        if caffeineFree.count >= 5 {
            unlock("sleeping_well")
        }

        // MARK: - Holiday badges

        for entry in entries {
            let month = calendar.component(.month, from: entry.timestamp)
            let day = calendar.component(.day, from: entry.timestamp)

            // New Year's Day
            if month == 1 && day == 1 {
                unlock("new_year_new_dc")
            }

            // Halloween
            if month == 10 && day == 31 {
                unlock("spooky_sip")
            }

            // Thanksgiving (4th Thursday of November) - approximate with Nov 22-28
            if month == 11 && day >= 22 && day <= 28 {
                let weekday = calendar.component(.weekday, from: entry.timestamp)
                if weekday == 5 { // Thursday
                    unlock("turkey_and_dc")
                }
            }

            // Christmas
            if month == 12 && day == 25 {
                unlock("holiday_spirit")
            }
        }

        // MARK: - Creature of Habit - same hour 3 days in a row

        let sortedDays = entriesByDay.keys.sorted()
        guard sortedDays.count >= 3 else { return }
        for i in 0..<(sortedDays.count - 2) {
            let day1 = sortedDays[i]
            let day2 = sortedDays[i + 1]
            let day3 = sortedDays[i + 2]

            // Check if consecutive days
            if let nextDay1 = calendar.date(byAdding: .day, value: 1, to: day1),
               let nextDay2 = calendar.date(byAdding: .day, value: 1, to: day2),
               calendar.isDate(nextDay1, inSameDayAs: day2),
               calendar.isDate(nextDay2, inSameDayAs: day3) {

                let hours1 = Set((entriesByDay[day1] ?? []).map { calendar.component(.hour, from: $0.timestamp) })
                let hours2 = Set((entriesByDay[day2] ?? []).map { calendar.component(.hour, from: $0.timestamp) })
                let hours3 = Set((entriesByDay[day3] ?? []).map { calendar.component(.hour, from: $0.timestamp) })

                let commonHours = hours1.intersection(hours2).intersection(hours3)
                if !commonHours.isEmpty {
                    unlock("creature_of_habit")
                    break
                }
            }
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
            AppLogger.store.error("Failed to save badges: \(error.localizedDescription)")
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
            AppLogger.store.error("Failed to load badges: \(error.localizedDescription)")
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
            AppLogger.sync.error("Badge sync failed: \(error.localizedDescription)")
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

    func unlock(_ badgeId: String, on date: Date) {
        guard !isUnlocked(badgeId) else { return }
        unlockedBadges[badgeId] = date
        saveBadges()
    }
    #endif
}
