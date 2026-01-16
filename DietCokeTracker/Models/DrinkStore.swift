import Foundation
import SwiftUI
import WidgetKit
import UIKit

@MainActor
class DrinkStore: ObservableObject {
    @Published private(set) var entries: [DrinkEntry] = []

    private let saveKey = "DietCokeEntries"

    init() {
        loadEntries()
    }

    // MARK: - CRUD Operations

    func addEntry(_ entry: DrinkEntry) {
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        saveEntries()
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
    }

    func deleteEntries(at offsets: IndexSet) {
        // Delete associated photos
        for index in offsets {
            if let photoFilename = entries[index].photoFilename {
                PhotoStorage.deletePhoto(filename: photoFilename)
            }
        }
        entries.remove(atOffsets: offsets)
        saveEntries()
    }

    func updateNote(for entry: DrinkEntry, note: String?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.note = note
            entries[index] = updated
            saveEntries()
        }
    }

    func updateTimestamp(for entry: DrinkEntry, timestamp: Date) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.timestamp = timestamp
            entries[index] = updated
            entries.sort { $0.timestamp > $1.timestamp }
            saveEntries()
        }
    }

    func updateRating(for entry: DrinkEntry, rating: DrinkRating?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.rating = rating
            entries[index] = updated
            saveEntries()
        }
    }

    func updateCustomOunces(for entry: DrinkEntry, customOunces: Double?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entries[index]
            updated.customOunces = customOunces
            entries[index] = updated
            saveEntries()
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

    private func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            sharedDefaults?.set(data, forKey: saveKey)

            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save entries: \(error)")
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
            print("Failed to load entries: \(error)")
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

    func clearAllData() {
        entries.removeAll()
        saveEntries()
    }
    #endif
}
