import Foundation
import CloudKit

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
        guard let idString = record["connectionID"] as? String,
              let id = UUID(uuidString: idString),
              let requesterID = record["requesterID"] as? String,
              let targetID = record["targetID"] as? String,
              let statusString = record["status"] as? String,
              let status = FriendStatus(rawValue: statusString),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

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
