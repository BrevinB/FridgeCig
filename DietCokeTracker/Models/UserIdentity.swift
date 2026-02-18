import Foundation
import CloudKit

struct UserIdentity: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var friendCode: String
    var username: String?
    var createdAt: Date

    init(id: UUID = UUID(), displayName: String, friendCode: String, username: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.username = username
        self.createdAt = createdAt
    }

    static func create(displayName: String, username: String? = nil, createdAt: Date = Date()) async -> UserIdentity {
        let friendCode = await CloudKitManager.generateFriendCode()
        return UserIdentity(displayName: displayName, friendCode: friendCode, username: username, createdAt: createdAt)
    }

    var userIDString: String {
        id.uuidString
    }
}

// MARK: - CloudKit Conversion

extension UserIdentity {
    static let recordType = "UserIdentity"

    init?(from record: CKRecord) {
        guard let idString = record["userID"] as? String,
              let id = UUID(uuidString: idString),
              let displayName = record["displayName"] as? String,
              let friendCode = record["friendCode"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.username = record["username"] as? String
        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record["userID"] = userIDString
        record["displayName"] = displayName
        record["friendCode"] = friendCode
        record["username"] = username
        record["createdAt"] = createdAt
        return record
    }

    func toCKRecord(existingRecordID: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: existingRecordID)
        record["userID"] = userIDString
        record["displayName"] = displayName
        record["friendCode"] = friendCode
        record["username"] = username
        record["createdAt"] = createdAt
        return record
    }
}

// MARK: - CloudRecord Conversion (Provider-Agnostic)

extension UserIdentity {
    init?(from record: CloudRecord) {
        guard let idString = record["userID"]?.stringValue,
              let id = UUID(uuidString: idString),
              let displayName = record["displayName"]?.stringValue,
              let friendCode = record["friendCode"]?.stringValue,
              let createdAt = record["createdAt"]?.dateValue else {
            return nil
        }

        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.username = record["username"]?.stringValue
        self.createdAt = createdAt
    }

    func toCloudRecord(existingRecordID: String? = nil) -> CloudRecord {
        var fields: [String: CloudValue] = [
            "userID": .string(userIDString),
            "displayName": .string(displayName),
            "friendCode": .string(friendCode),
            "createdAt": .date(createdAt),
        ]

        if let username = username { fields["username"] = .string(username) }

        return CloudRecord(
            recordType: Self.recordType,
            recordID: existingRecordID ?? "",
            fields: fields
        )
    }
}
