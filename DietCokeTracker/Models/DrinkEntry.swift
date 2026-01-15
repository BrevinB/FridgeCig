import Foundation
import Combine

struct DrinkEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let type: DrinkType
    var timestamp: Date
    var note: String?
    var specialEdition: SpecialEdition?
    var customOunces: Double?
    var rating: DrinkRating?

    init(id: UUID = UUID(), type: DrinkType, timestamp: Date = Date(), note: String? = nil, specialEdition: SpecialEdition? = nil, customOunces: Double? = nil, rating: DrinkRating? = nil) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.note = note
        self.specialEdition = specialEdition
        self.customOunces = customOunces
        self.rating = rating
    }

    var isSpecialEdition: Bool {
        specialEdition != nil
    }

    var hasCustomOunces: Bool {
        customOunces != nil
    }

    var ounces: Double {
        customOunces ?? type.ounces
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }

    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(timestamp, equalTo: Date(), toGranularity: .month)
    }
}

extension Array where Element == DrinkEntry {
    var totalOunces: Double {
        reduce(0) { $0 + $1.ounces }
    }

    var todayEntries: [DrinkEntry] {
        filter { $0.isToday }
    }

    var thisWeekEntries: [DrinkEntry] {
        filter { $0.isThisWeek }
    }

    var thisMonthEntries: [DrinkEntry] {
        filter { $0.isThisMonth }
    }

    func entries(for date: Date) -> [DrinkEntry] {
        filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }

    func groupedByDay() -> [Date: [DrinkEntry]] {
        Dictionary(grouping: self) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }

    func groupedByType() -> [DrinkType: [DrinkEntry]] {
        Dictionary(grouping: self) { $0.type }
    }
}
