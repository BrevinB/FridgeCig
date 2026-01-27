import Foundation
import SwiftUI
import CloudKit

// MARK: - Activity Type

enum ActivityType: String, Codable {
    case badgeUnlock       // User unlocked a badge
    case streakMilestone   // User hit a streak milestone (7, 30, 100+ days)
    case drinkLog          // User logged a drink (opt-in, with photo)

    var icon: String {
        switch self {
        case .badgeUnlock: return "trophy.fill"
        case .streakMilestone: return "flame.fill"
        case .drinkLog: return "cup.and.saucer.fill"
        }
    }

    var color: Color {
        switch self {
        case .badgeUnlock: return .yellow
        case .streakMilestone: return .orange
        case .drinkLog: return .dietCokeRed
        }
    }
}

// MARK: - Activity Item

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let userID: String
    let displayName: String
    let type: ActivityType
    let timestamp: Date
    let payload: ActivityPayload
    var cheersCount: Int
    var cheersUserIDs: [String]

    init(
        id: UUID = UUID(),
        userID: String,
        displayName: String,
        type: ActivityType,
        timestamp: Date = Date(),
        payload: ActivityPayload,
        cheersCount: Int = 0,
        cheersUserIDs: [String] = []
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
        self.cheersCount = cheersCount
        self.cheersUserIDs = cheersUserIDs
    }

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var title: String {
        switch type {
        case .badgeUnlock:
            return "\(displayName) earned a badge"
        case .streakMilestone:
            if let streakDays = payload.streakDays {
                return "\(displayName) hit a \(streakDays)-day streak"
            }
            return "\(displayName) is on a streak"
        case .drinkLog:
            return "\(displayName) logged a drink"
        }
    }

    var subtitle: String? {
        switch type {
        case .badgeUnlock:
            return payload.badgeTitle
        case .streakMilestone:
            return payload.streakMessage
        case .drinkLog:
            return payload.drinkType?.displayName
        }
    }
}

// MARK: - Activity Payload

struct ActivityPayload: Codable {
    // Badge info
    var badgeID: String?
    var badgeTitle: String?
    var badgeIcon: String?
    var badgeRarity: BadgeRarity?

    // Streak info
    var streakDays: Int?
    var streakMessage: String?

    // Drink log info
    var drinkType: DrinkType?
    var drinkNote: String?
    var hasPhoto: Bool?
    var photoURL: String?  // CloudKit asset URL for shared photos

    init(
        badgeID: String? = nil,
        badgeTitle: String? = nil,
        badgeIcon: String? = nil,
        badgeRarity: BadgeRarity? = nil,
        streakDays: Int? = nil,
        streakMessage: String? = nil,
        drinkType: DrinkType? = nil,
        drinkNote: String? = nil,
        hasPhoto: Bool? = nil,
        photoURL: String? = nil
    ) {
        self.badgeID = badgeID
        self.badgeTitle = badgeTitle
        self.badgeIcon = badgeIcon
        self.badgeRarity = badgeRarity
        self.streakDays = streakDays
        self.streakMessage = streakMessage
        self.drinkType = drinkType
        self.drinkNote = drinkNote
        self.hasPhoto = hasPhoto
        self.photoURL = photoURL
    }

    // MARK: - Factory Methods

    static func forBadge(_ badge: Badge) -> ActivityPayload {
        ActivityPayload(
            badgeID: badge.id,
            badgeTitle: badge.title,
            badgeIcon: badge.icon,
            badgeRarity: badge.rarity
        )
    }

    static func forStreak(_ days: Int) -> ActivityPayload {
        let message: String
        switch days {
        case 7: message = "One week strong!"
        case 30: message = "A whole month!"
        case 100: message = "Century club!"
        case 365: message = "A full year!"
        default: message = "Keep it going!"
        }

        return ActivityPayload(
            streakDays: days,
            streakMessage: message
        )
    }

    static func forDrink(type: DrinkType, note: String?, hasPhoto: Bool, photoURL: String? = nil) -> ActivityPayload {
        ActivityPayload(
            drinkType: type,
            drinkNote: note,
            hasPhoto: hasPhoto,
            photoURL: photoURL
        )
    }
}

// MARK: - User Sharing Preferences

struct UserSharingPreferences: Codable {
    var shareBadges: Bool
    var shareStreakMilestones: Bool
    var shareDrinkLogs: Bool
    var showPhotosInFeed: Bool

    init(
        shareBadges: Bool = true,
        shareStreakMilestones: Bool = true,
        shareDrinkLogs: Bool = false,
        showPhotosInFeed: Bool = false
    ) {
        self.shareBadges = shareBadges
        self.shareStreakMilestones = shareStreakMilestones
        self.shareDrinkLogs = shareDrinkLogs
        self.showPhotosInFeed = showPhotosInFeed
    }

    static let `default` = UserSharingPreferences()
}

// MARK: - CloudKit Conversion

extension ActivityItem {
    static let recordType = "ActivityItem"

    init?(from record: CKRecord) {
        guard let activityIDString = record["activityID"] as? String,
              let activityID = UUID(uuidString: activityIDString),
              let userID = record["userID"] as? String,
              let displayName = record["displayName"] as? String,
              let typeRaw = record["type"] as? String,
              let type = ActivityType(rawValue: typeRaw),
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }

        self.id = activityID
        self.userID = userID
        self.displayName = displayName
        self.type = type
        self.timestamp = timestamp
        self.cheersCount = (record["cheersCount"] as? Int64).map { Int($0) } ?? 0
        self.cheersUserIDs = record["cheersUserIDs"] as? [String] ?? []

        // Decode payload from JSON
        if let payloadJSON = record["payloadJSON"] as? String,
           let payloadData = payloadJSON.data(using: .utf8),
           let payload = try? JSONDecoder().decode(ActivityPayload.self, from: payloadData) {
            self.payload = payload
        } else {
            self.payload = ActivityPayload()
        }
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        populateRecord(record)
        return record
    }

    func toCKRecord(existingRecordID: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: existingRecordID)
        populateRecord(record)
        return record
    }

    private func populateRecord(_ record: CKRecord) {
        record["activityID"] = id.uuidString
        record["userID"] = userID
        record["displayName"] = displayName
        record["type"] = type.rawValue
        record["timestamp"] = timestamp
        record["cheersCount"] = cheersCount
        // CloudKit can't initialize a new field with an empty array, so only set if non-empty
        if !cheersUserIDs.isEmpty {
            record["cheersUserIDs"] = cheersUserIDs
        }

        // Encode payload to JSON
        if let payloadData = try? JSONEncoder().encode(payload),
           let payloadJSON = String(data: payloadData, encoding: .utf8) {
            record["payloadJSON"] = payloadJSON
        }
    }
}
