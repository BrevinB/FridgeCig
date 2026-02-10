import Foundation
import SwiftUI
import WidgetKit
import UIKit
import Combine
import os

@MainActor
class DrinkStore: ObservableObject {
    @Published private(set) var entries: [DrinkEntry] = []
    @Published var isSyncing = false
    @Published var syncError: Error?

    /// Publisher that emits when entries change (for stats sync)
    let entriesDidChange = PassthroughSubject<Void, Never>()

    /// Publisher that emits when a new drink is added (for activity feed)
    let drinkAdded = PassthroughSubject<(entry: DrinkEntry, photo: UIImage?), Never>()

    /// Publisher that emits when a drink is deleted (for activity feed cleanup)
    let drinkDeleted = PassthroughSubject<DrinkEntry, Never>()

    /// Publisher that emits when streak changes (for activity feed milestones)
    let streakChanged = PassthroughSubject<Int, Never>()

    private let saveKey = "DietCokeEntries"
    private var lastKnownStreak: Int = 0

    /// Sync service for CloudKit (set by app on launch)
    var syncService: DrinkSyncService?

    // MARK: - Rate Limiting State

    /// Last time an entry was added (for rate limiting)
    @Published private(set) var lastEntryTime: Date?

    init() {
        loadEntries()
        updateRateLimitState()
        setupWatchNotifications()
    }

    // MARK: - Watch Connectivity

    private func setupWatchNotifications() {
        NotificationCenter.default.addObserver(
            forName: .watchDidAddEntry,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let entry = notification.userInfo?["entry"] as? DrinkEntry else { return }

            Task { @MainActor in
                self.mergeEntryFromWatch(entry)
            }
        }
    }

    private func mergeEntryFromWatch(_ entry: DrinkEntry) {
        // Check if entry already exists (avoid duplicates)
        guard !entries.contains(where: { $0.id == entry.id }) else {
            AppLogger.store.debug("Entry from Watch already exists, skipping")
            return
        }

        AppLogger.store.info("Merging entry from Watch: \(entry.type.displayName)")

        // Track streak before adding
        let streakBefore = streakDays

        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        saveEntries()

        // Update rate limiting state
        lastEntryTime = Date()

        // Check if streak changed
        let streakAfter = streakDays
        if streakAfter != streakBefore {
            lastKnownStreak = streakAfter
            streakChanged.send(streakAfter)
        }

        // Sync rate limiting to shared storage
        SharedDataManager.recordEntryAdded()

        // Notify for activity feed posting
        drinkAdded.send((entry: entry, photo: nil))

        // Sync to cloud
        Task {
            do {
                try await syncService?.uploadEntry(entry)
            } catch {
                AppLogger.sync.error("Failed to upload watch entry: \(error.localizedDescription)")
                self.syncError = error
            }
        }

        // Log to HealthKit (non-critical)
        Task {
            do {
                try await HealthKitManager.shared.logDrink(entry: entry)
            } catch {
                AppLogger.healthKit.error("Failed to log watch entry to HealthKit: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Rate Limiting

    /// Check if a new entry can be added (rate limiting)
    func canAddEntry() -> EntryValidator.ValidationResult {
        return EntryValidator.canAddEntry(lastEntryTime: lastEntryTime)
    }

    /// Validate a timestamp before allowing entry
    func validateTimestamp(_ date: Date) -> EntryValidator.ValidationResult {
        return EntryValidator.validateTimestamp(date)
    }

    /// Validate custom ounces amount
    func validateOunces(_ ounces: Double) -> EntryValidator.ValidationResult {
        return EntryValidator.validateOunces(ounces)
    }

    /// Check if entry would be a duplicate
    func checkDuplicate(ounces: Double, type: DrinkType) -> EntryValidator.ValidationResult {
        return EntryValidator.isDuplicate(
            ounces: ounces,
            type: type,
            timestamp: Date(),
            existingEntries: entries
        )
    }

    /// Full validation before adding a drink
    func validateNewEntry(
        type: DrinkType,
        customOunces: Double?,
        timestamp: Date = Date()
    ) -> EntryValidator.ValidationResult {
        // Check rate limiting
        let rateResult = canAddEntry()
        if !rateResult.isValid {
            return rateResult
        }

        // Check timestamp
        let timestampResult = validateTimestamp(timestamp)
        if !timestampResult.isValid {
            return timestampResult
        }

        // Check ounces if custom
        if let oz = customOunces {
            let ouncesResult = validateOunces(oz)
            if !ouncesResult.isValid {
                return ouncesResult
            }
        }

        // Check duplicate
        let ounces = customOunces ?? type.ounces
        let duplicateResult = checkDuplicate(ounces: ounces, type: type)
        if !duplicateResult.isValid {
            return duplicateResult
        }

        return .valid()
    }

    private func updateRateLimitState() {
        // Find the most recent entry timestamp
        lastEntryTime = entries.first?.timestamp
    }

    // MARK: - CloudKit Sync

    /// Perform full sync with CloudKit
    func performSync() async {
        guard let syncService = syncService else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let merged = try await syncService.performFullSync(localEntries: entries)
            entries = merged
            saveEntries(triggerCloudSync: false)
        } catch {
            AppLogger.sync.error("Sync failed: \(error.localizedDescription)")
            syncError = error
        }
    }

    // MARK: - CRUD Operations

    func addEntry(_ entry: DrinkEntry) {
        // Track streak before adding
        let streakBefore = streakDays

        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        saveEntries()

        // Update rate limiting state
        lastEntryTime = Date()

        // Check if streak changed
        let streakAfter = streakDays
        if streakAfter != streakBefore {
            lastKnownStreak = streakAfter
            streakChanged.send(streakAfter)
        }

        // Sync rate limiting to shared storage (for widgets/watch)
        SharedDataManager.recordEntryAdded()

        // Sync to cloud
        Task {
            do {
                try await syncService?.uploadEntry(entry)
            } catch {
                AppLogger.sync.error("Failed to upload entry: \(error.localizedDescription)")
                self.syncError = error
            }
        }
    }

    func addDrink(type: DrinkType, brand: BeverageBrand = .dietCoke, note: String? = nil, specialEdition: SpecialEdition? = nil, customOunces: Double? = nil, rating: DrinkRating? = nil, photo: UIImage? = nil) {
        var photoFilename: String? = nil

        // Save photo if provided
        if let photo = photo {
            let filename = PhotoStorage.generateFilename()
            if PhotoStorage.savePhoto(photo, filename: filename) {
                photoFilename = filename
            }
        }

        let entry = DrinkEntry(type: type, brand: brand, note: note, specialEdition: specialEdition, customOunces: customOunces, rating: rating, photoFilename: photoFilename)
        addEntry(entry)

        // Notify for activity feed posting
        AppLogger.store.debug("Sending drinkAdded notification for: \(entry.type.displayName)")
        drinkAdded.send((entry: entry, photo: photo))

        // Log to HealthKit if enabled (non-critical)
        Task {
            do {
                try await HealthKitManager.shared.logDrink(entry: entry)
            } catch {
                AppLogger.healthKit.error("Failed to log drink to HealthKit: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Badge Integration

    func checkBadges(with badgeStore: BadgeStore) {
        badgeStore.checkAchievements(entries: entries, streak: streakDays)
    }

    func deleteEntry(_ entry: DrinkEntry) {
        // Delete associated photo if exists
        if let photoFilename = entry.photoFilename {
            PhotoStorage.deletePhoto(filename: photoFilename)
        }
        entries.removeAll { $0.id == entry.id }
        saveEntries()

        // Update rate limiting state (clears cooldown if deleted entry was most recent)
        updateRateLimitState()

        // Notify for activity feed deletion
        drinkDeleted.send(entry)

        // Sync deletion to cloud and HealthKit
        Task {
            do {
                try await syncService?.deleteEntry(entry)
            } catch {
                AppLogger.sync.error("Failed to delete entry from cloud: \(error.localizedDescription)")
                self.syncError = error
            }
            do {
                try await HealthKitManager.shared.deleteDrink(entry: entry)
            } catch {
                AppLogger.healthKit.error("Failed to delete drink from HealthKit: \(error.localizedDescription)")
            }
        }
    }

    func deleteEntries(at offsets: IndexSet) {
        // Collect entries to delete for cloud sync
        let entriesToDelete = offsets.map { entries[$0] }

        // Delete associated photos
        for entry in entriesToDelete {
            if let photoFilename = entry.photoFilename {
                PhotoStorage.deletePhoto(filename: photoFilename)
            }
        }
        entries.remove(atOffsets: offsets)
        saveEntries()

        // Update rate limiting state (clears cooldown if deleted entries included most recent)
        updateRateLimitState()

        // Notify for activity feed deletion
        for entry in entriesToDelete {
            drinkDeleted.send(entry)
        }

        // Sync deletions to cloud and HealthKit
        Task {
            for entry in entriesToDelete {
                do {
                    try await syncService?.deleteEntry(entry)
                } catch {
                    AppLogger.sync.error("Failed to delete entry from cloud: \(error.localizedDescription)")
                    self.syncError = error
                }
                do {
                    try await HealthKitManager.shared.deleteDrink(entry: entry)
                } catch {
                    AppLogger.healthKit.error("Failed to delete drink from HealthKit: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateNote(for entry: DrinkEntry, note: String?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.note = note
            entries[index] = updated
            saveEntries()
            syncEntry(updated)
        }
    }

    func updateTimestamp(for entry: DrinkEntry, timestamp: Date) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.timestamp = timestamp
            entries[index] = updated
            entries.sort { $0.timestamp > $1.timestamp }
            saveEntries()
            syncEntry(updated)
        }
    }

    func updateRating(for entry: DrinkEntry, rating: DrinkRating?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.rating = rating
            entries[index] = updated
            saveEntries()
            syncEntry(updated)
        }
    }

    func updateCustomOunces(for entry: DrinkEntry, customOunces: Double?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.customOunces = customOunces
            entries[index] = updated
            saveEntries()
            syncEntry(updated)
        }
    }

    private func syncEntry(_ entry: DrinkEntry) {
        Task {
            do {
                try await syncService?.updateEntry(entry)
            } catch {
                AppLogger.sync.error("Failed to sync entry update: \(error.localizedDescription)")
                self.syncError = error
            }
        }
    }

    // MARK: - Statistics

    var todayCount: Int {
        entries.todayEntries.count
    }

    var todayOunces: Double {
        entries.todayEntries.totalOunces
    }

    var thisWeekCount: Int {
        entries.thisWeekEntries.count
    }

    var thisWeekOunces: Double {
        entries.thisWeekEntries.totalOunces
    }

    var thisMonthCount: Int {
        entries.thisMonthEntries.count
    }

    var thisMonthOunces: Double {
        entries.thisMonthEntries.totalOunces
    }

    var allTimeCount: Int {
        entries.count
    }

    var allTimeOunces: Double {
        entries.totalOunces
    }

    var averagePerDay: Double {
        guard !entries.isEmpty else { return 0 }
        let grouped = entries.groupedByDay()
        return Double(entries.count) / Double(grouped.count)
    }

    var mostPopularType: DrinkType? {
        let grouped = entries.groupedByType()
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    var streakDays: Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasEntry = entries.contains { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: checkDate)
            }

            if hasEntry {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    func entriesForDate(_ date: Date) -> [DrinkEntry] {
        entries.entries(for: date)
    }

    func countByType() -> [DrinkType: Int] {
        Dictionary(grouping: entries) { $0.type }
            .mapValues { $0.count }
    }

    func ouncesLast7Days() -> [(date: Date, ounces: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return nil
            }
            let dayEntries = entries.entries(for: date)
            return (date: date, ounces: dayEntries.totalOunces)
        }.reversed()
    }

    // MARK: - Persistence (App Groups for Widget sharing)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupID)
    }

    private func saveEntries(triggerCloudSync: Bool = true) {
        do {
            let data = try JSONEncoder().encode(entries)
            sharedDefaults?.set(data, forKey: saveKey)

            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()

            // Sync to Apple Watch
            WatchConnectivityManager.shared.syncEntriesToWatch(entries)

            // Notify listeners for stats sync
            if triggerCloudSync {
                entriesDidChange.send()
            }
        } catch {
            AppLogger.store.error("Failed to save entries: \(error.localizedDescription)")
        }
    }

    private func loadEntries() {
        guard let data = sharedDefaults?.data(forKey: saveKey) else {
            return
        }

        do {
            entries = try JSONDecoder().decode([DrinkEntry].self, from: data)
            entries.sort { $0.timestamp > $1.timestamp }
        } catch {
            AppLogger.store.error("Failed to load entries: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug/Testing

    #if DEBUG
    func addSampleData() {
        let calendar = Calendar.current
        let types = DrinkType.allCases

        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let count = Int.random(in: 1...5)
            for _ in 0..<count {
                let type = types.randomElement()!
                let hour = Int.random(in: 8...22)
                let minute = Int.random(in: 0...59)

                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute

                if let timestamp = calendar.date(from: components) {
                    let entry = DrinkEntry(type: type, timestamp: timestamp)
                    entries.append(entry)
                }
            }
        }

        entries.sort { $0.timestamp > $1.timestamp }
        saveEntries()
    }
    #endif

    // MARK: - Data Management

    /// Clear all local drink data (used for account deletion)
    func clearAllData() {
        entries.removeAll()
        saveEntries()
    }
}
