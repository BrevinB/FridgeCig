import Foundation
import CloudKit

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var friendCode: String
    var username: String?
    var isPublic: Bool

    // Leaderboard stats
    var currentStreak: Int
    var weeklyDrinks: Int
    var weeklyOunces: Double
    var monthlyDrinks: Int
    var monthlyOunces: Double
    var allTimeDrinks: Int
    var allTimeOunces: Double
    var statsUpdatedAt: Date

    // Anti-abuse verification fields
    var entryCount: Int
    var averageOuncesPerEntry: Double
    var isSuspicious: Bool
    var suspiciousFlags: [String]

    // Premium status (synced from subscription)
    var isPremium: Bool

    var userIDString: String {
        id.uuidString
    }

    init(from identity: UserIdentity) {
        self.id = identity.id
        self.displayName = identity.displayName
        self.friendCode = identity.friendCode
        self.username = identity.username
        self.isPublic = true  // Default to visible on global leaderboard
        self.currentStreak = 0
        self.weeklyDrinks = 0
        self.weeklyOunces = 0
        self.monthlyDrinks = 0
        self.monthlyOunces = 0
        self.allTimeDrinks = 0
        self.allTimeOunces = 0
        self.statsUpdatedAt = Date()

        // Verification defaults
        self.entryCount = 0
        self.averageOuncesPerEntry = 0
        self.isSuspicious = false
        self.suspiciousFlags = []
        self.isPremium = false
    }
}

// MARK: - CloudKit Conversion

extension UserProfile {
    static let recordType = "UserProfile"

    init?(from record: CKRecord) {
        guard let idString = record["userID"] as? String,
              let id = UUID(uuidString: idString),
              let displayName = record["displayName"] as? String,
              let friendCode = record["friendCode"] as? String else {
            return nil
        }

        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.username = record["username"] as? String
        self.isPublic = (record["isPublic"] as? Int64 ?? 0) == 1

        self.currentStreak = (record["currentStreak"] as? Int64).map { Int($0) } ?? 0
        self.weeklyDrinks = (record["weeklyDrinks"] as? Int64).map { Int($0) } ?? 0
        self.weeklyOunces = record["weeklyOunces"] as? Double ?? 0
        self.monthlyDrinks = (record["monthlyDrinks"] as? Int64).map { Int($0) } ?? 0
        self.monthlyOunces = record["monthlyOunces"] as? Double ?? 0
        self.allTimeDrinks = (record["allTimeDrinks"] as? Int64).map { Int($0) } ?? 0
        self.allTimeOunces = record["allTimeOunces"] as? Double ?? 0
        self.statsUpdatedAt = record["statsUpdatedAt"] as? Date ?? Date()

        // Anti-abuse verification fields
        self.entryCount = (record["entryCount"] as? Int64).map { Int($0) } ?? 0
        self.averageOuncesPerEntry = record["averageOuncesPerEntry"] as? Double ?? 0
        self.isSuspicious = (record["isSuspicious"] as? Int64 ?? 0) == 1
        self.suspiciousFlags = record["suspiciousFlags"] as? [String] ?? []
        self.isPremium = (record["isPremium"] as? Int64 ?? 0) == 1
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
        record["userID"] = userIDString
        record["displayName"] = displayName
        record["friendCode"] = friendCode
        record["username"] = username
        record["isPublic"] = isPublic ? 1 : 0

        record["currentStreak"] = currentStreak
        record["weeklyDrinks"] = weeklyDrinks
        record["weeklyOunces"] = weeklyOunces
        record["monthlyDrinks"] = monthlyDrinks
        record["monthlyOunces"] = monthlyOunces
        record["allTimeDrinks"] = allTimeDrinks
        record["allTimeOunces"] = allTimeOunces
        record["statsUpdatedAt"] = statsUpdatedAt

        // Anti-abuse verification fields
        record["entryCount"] = entryCount
        record["averageOuncesPerEntry"] = averageOuncesPerEntry
        record["isSuspicious"] = isSuspicious ? 1 : 0
        // CloudKit can't initialize a new field with an empty array, so only set if non-empty
        record["suspiciousFlags"] = suspiciousFlags.isEmpty ? nil : suspiciousFlags
        record["isPremium"] = isPremium ? 1 : 0
    }
}

// MARK: - Stats Update

extension UserProfile {
    mutating func updateStats(
        streak: Int,
        weeklyDrinks: Int,
        weeklyOunces: Double,
        monthlyDrinks: Int,
        monthlyOunces: Double,
        allTimeDrinks: Int,
        allTimeOunces: Double,
        entryCount: Int,
        patternResult: SuspiciousPatternResult
    ) {
        self.currentStreak = streak
        self.weeklyDrinks = weeklyDrinks
        self.weeklyOunces = weeklyOunces
        self.monthlyDrinks = monthlyDrinks
        self.monthlyOunces = monthlyOunces
        self.allTimeDrinks = allTimeDrinks
        self.allTimeOunces = allTimeOunces
        self.statsUpdatedAt = Date()

        // Verification fields
        self.entryCount = entryCount
        self.averageOuncesPerEntry = entryCount > 0 ? allTimeOunces / Double(entryCount) : 0
        self.isSuspicious = patternResult.isSuspicious
        self.suspiciousFlags = patternResult.flags
    }

    /// Legacy method for backwards compatibility
    mutating func updateStats(streak: Int, weeklyDrinks: Int, weeklyOunces: Double, monthlyDrinks: Int, monthlyOunces: Double, allTimeDrinks: Int, allTimeOunces: Double) {
        updateStats(
            streak: streak,
            weeklyDrinks: weeklyDrinks,
            weeklyOunces: weeklyOunces,
            monthlyDrinks: monthlyDrinks,
            monthlyOunces: monthlyOunces,
            allTimeDrinks: allTimeDrinks,
            allTimeOunces: allTimeOunces,
            entryCount: allTimeDrinks, // Approximate
            patternResult: SuspiciousPatternResult(isSuspicious: false, flags: [], confidenceScore: 0)
        )
    }
}
