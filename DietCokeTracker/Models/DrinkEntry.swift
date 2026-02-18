import Foundation
import Combine
import CloudKit

struct DrinkEntry: Identifiable, Equatable {
    let id: UUID
    let type: DrinkType
    var brand: BeverageBrand
    var timestamp: Date
    var note: String?
    var specialEdition: SpecialEdition?
    var customOunces: Double?
    var rating: DrinkRating?
    var photoFilename: String?

    /// Immutable timestamp of when the entry was actually created (for audit trail)
    let createdAt: Date

    init(id: UUID = UUID(), type: DrinkType, brand: BeverageBrand = .dietCoke, timestamp: Date = Date(), note: String? = nil, specialEdition: SpecialEdition? = nil, customOunces: Double? = nil, rating: DrinkRating? = nil, photoFilename: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.brand = brand
        self.timestamp = timestamp
        self.note = note
        self.specialEdition = specialEdition
        self.customOunces = customOunces
        self.rating = rating
        self.photoFilename = photoFilename
        self.createdAt = createdAt
    }

    var hasPhoto: Bool {
        photoFilename != nil
    }
}

// MARK: - Codable (with backwards compatibility)

extension DrinkEntry: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, brand, timestamp, note, specialEdition, customOunces, rating, photoFilename, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(DrinkType.self, forKey: .type)
        // Default to dietCoke for existing entries without brand
        brand = try container.decodeIfPresent(BeverageBrand.self, forKey: .brand) ?? .dietCoke
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        specialEdition = try container.decodeIfPresent(SpecialEdition.self, forKey: .specialEdition)
        customOunces = try container.decodeIfPresent(Double.self, forKey: .customOunces)
        rating = try container.decodeIfPresent(DrinkRating.self, forKey: .rating)
        photoFilename = try container.decodeIfPresent(String.self, forKey: .photoFilename)
        // Default createdAt to timestamp for existing entries (backwards compatibility)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? timestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(brand, forKey: .brand)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(specialEdition, forKey: .specialEdition)
        try container.encodeIfPresent(customOunces, forKey: .customOunces)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(photoFilename, forKey: .photoFilename)
        try container.encode(createdAt, forKey: .createdAt)
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

// MARK: - CloudKit Conversion

extension DrinkEntry {
    static let recordType = "DrinkEntry"

    /// Create from CloudKit record
    init?(from record: CKRecord) {
        guard let idString = record["entryID"] as? String,
              let id = UUID(uuidString: idString),
              let typeRaw = record["type"] as? String,
              let type = DrinkType(rawValue: typeRaw),
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }

        self.id = id
        self.type = type
        self.timestamp = timestamp

        // Optional fields
        if let brandRaw = record["brand"] as? String {
            self.brand = BeverageBrand(rawValue: brandRaw) ?? .dietCoke
        } else {
            self.brand = .dietCoke
        }

        self.note = record["note"] as? String

        if let specialRaw = record["specialEdition"] as? String {
            self.specialEdition = SpecialEdition(rawValue: specialRaw)
        } else {
            self.specialEdition = nil
        }

        self.customOunces = record["customOunces"] as? Double

        if let ratingInt = record["rating"] as? Int64 {
            self.rating = DrinkRating(rawValue: Int(ratingInt))
        } else {
            self.rating = nil
        }

        self.photoFilename = record["photoFilename"] as? String

        // Default createdAt to timestamp for older records
        self.createdAt = record["createdAt"] as? Date ?? timestamp
    }

    /// Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        populateRecord(record)
        return record
    }

    /// Convert to CloudKit record with existing ID (for updates)
    func toCKRecord(existingRecordID: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: existingRecordID)
        populateRecord(record)
        return record
    }

    private func populateRecord(_ record: CKRecord) {
        record["entryID"] = id.uuidString
        record["type"] = type.rawValue
        record["brand"] = brand.rawValue
        record["timestamp"] = timestamp
        record["note"] = note
        record["specialEdition"] = specialEdition?.rawValue
        record["customOunces"] = customOunces
        record["rating"] = rating?.rawValue
        record["photoFilename"] = photoFilename
        record["createdAt"] = createdAt
    }
}

// MARK: - CloudRecord Conversion (Provider-Agnostic)

extension DrinkEntry {
    /// Create from a provider-agnostic CloudRecord
    init?(from record: CloudRecord) {
        guard let idString = record["entryID"]?.stringValue,
              let id = UUID(uuidString: idString),
              let typeRaw = record["type"]?.stringValue,
              let type = DrinkType(rawValue: typeRaw),
              let timestamp = record["timestamp"]?.dateValue else {
            return nil
        }

        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.brand = record["brand"]?.stringValue.flatMap { BeverageBrand(rawValue: $0) } ?? .dietCoke
        self.note = record["note"]?.stringValue
        self.specialEdition = record["specialEdition"]?.stringValue.flatMap { SpecialEdition(rawValue: $0) }
        self.customOunces = record["customOunces"]?.doubleValue
        self.rating = record["rating"]?.intValue.flatMap { DrinkRating(rawValue: $0) }
        self.photoFilename = record["photoFilename"]?.stringValue
        self.createdAt = record["createdAt"]?.dateValue ?? timestamp
    }

    /// Convert to a provider-agnostic CloudRecord
    func toCloudRecord(existingRecordID: String? = nil) -> CloudRecord {
        var fields: [String: CloudValue] = [
            "entryID": .string(id.uuidString),
            "type": .string(type.rawValue),
            "brand": .string(brand.rawValue),
            "timestamp": .date(timestamp),
            "createdAt": .date(createdAt),
        ]

        if let note = note { fields["note"] = .string(note) }
        if let specialEdition = specialEdition { fields["specialEdition"] = .string(specialEdition.rawValue) }
        if let customOunces = customOunces { fields["customOunces"] = .double(customOunces) }
        if let rating = rating { fields["rating"] = .int(rating.rawValue) }
        if let photoFilename = photoFilename { fields["photoFilename"] = .string(photoFilename) }

        return CloudRecord(
            recordType: Self.recordType,
            recordID: existingRecordID ?? "",
            fields: fields
        )
    }
}
