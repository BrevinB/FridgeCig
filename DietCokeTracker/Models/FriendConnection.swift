import Foundation
import CloudKit
import os

enum FriendStatus: String, Codable {
    case pending
    case accepted
    case blocked
}

struct FriendConnection: Codable, Identifiable {
    let id: UUID
    let requesterID: String
    let targetID: String
    var status: FriendStatus
    var createdAt: Date
    var acceptedAt: Date?

    init(id: UUID = UUID(), requesterID: String, targetID: String, status: FriendStatus = .pending, createdAt: Date = Date(), acceptedAt: Date? = nil) {
        self.id = id
        self.requesterID = requesterID
        self.targetID = targetID
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
    }

    func otherUserID(currentUserID: String) -> String {
        requesterID == currentUserID ? targetID : requesterID
    }
}

// MARK: - CloudKit Conversion

extension FriendConnection {
    static let recordType = "FriendConnection"

    init?(from record: CKRecord) {
        // Required fields
        guard let requesterID = record["requesterID"] as? String,
              let targetID = record["targetID"] as? String,
              let statusString = record["status"] as? String,
              let status = FriendStatus(rawValue: statusString) else {
            AppLogger.friends.error("FriendConnection parse failed - missing required field")
            AppLogger.friends.error("  requesterID: \(record["requesterID"] ?? "nil")")
            AppLogger.friends.error("  targetID: \(record["targetID"] ?? "nil")")
            AppLogger.friends.error("  status: \(record["status"] ?? "nil")")
            return nil
        }

        // Optional fields with fallbacks
        let id: UUID
        if let idString = record["connectionID"] as? String,
           let parsedID = UUID(uuidString: idString) {
            id = parsedID
        } else {
            // Generate deterministic ID from record name to ensure consistency
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
            AppLogger.friends.debug("connectionID missing, using recordID: \(id)")
        }

        // Use createdAt field, fall back to CloudKit's creation date
        let createdAt = record["createdAt"] as? Date ?? record.creationDate ?? Date()

        self.id = id
        self.requesterID = requesterID
        self.targetID = targetID
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = record["acceptedAt"] as? Date
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
        record["connectionID"] = id.uuidString
        record["requesterID"] = requesterID
        record["targetID"] = targetID
        record["status"] = status.rawValue
        record["createdAt"] = createdAt
        record["acceptedAt"] = acceptedAt
    }
}

// MARK: - CloudRecord Conversion (Provider-Agnostic)

extension FriendConnection {
    init?(from record: CloudRecord) {
        guard let requesterID = record["requesterID"]?.stringValue,
              let targetID = record["targetID"]?.stringValue,
              let statusString = record["status"]?.stringValue,
              let status = FriendStatus(rawValue: statusString) else {
            return nil
        }

        let id: UUID
        if let idString = record["connectionID"]?.stringValue,
           let parsedID = UUID(uuidString: idString) {
            id = parsedID
        } else {
            id = UUID(uuidString: record.recordID) ?? UUID()
        }

        let createdAt = record["createdAt"]?.dateValue ?? record.creationDate ?? Date()

        self.id = id
        self.requesterID = requesterID
        self.targetID = targetID
        self.status = status
        self.createdAt = createdAt
        self.acceptedAt = record["acceptedAt"]?.dateValue
    }

    func toCloudRecord(existingRecordID: String? = nil) -> CloudRecord {
        var fields: [String: CloudValue] = [
            "connectionID": .string(id.uuidString),
            "requesterID": .string(requesterID),
            "targetID": .string(targetID),
            "status": .string(status.rawValue),
            "createdAt": .date(createdAt),
        ]

        if let acceptedAt = acceptedAt { fields["acceptedAt"] = .date(acceptedAt) }

        return CloudRecord(
            recordType: Self.recordType,
            recordID: existingRecordID ?? "",
            fields: fields
        )
    }
}
