import Foundation
import CloudKit

/// A reply left on a feed post. Comments live in their own record type so a
/// busy post doesn't turn its activity record into a write-contention hotspot.
struct ActivityComment: Identifiable, Equatable, Codable {
    let id: UUID
    let activityID: UUID
    let authorID: String
    var authorName: String
    var authorPhotoID: String?
    var authorEmoji: String?
    var text: String
    let createdAt: Date

    /// Keeps comments glanceable in the feed and bounded in CloudKit.
    static let maxLength = 200

    init(
        id: UUID = UUID(),
        activityID: UUID,
        authorID: String,
        authorName: String,
        authorPhotoID: String? = nil,
        authorEmoji: String? = nil,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.activityID = activityID
        self.authorID = authorID
        self.authorName = authorName
        self.authorPhotoID = authorPhotoID
        self.authorEmoji = authorEmoji
        self.text = text
        self.createdAt = createdAt
    }

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Trims and truncates raw input. Returns nil when there's nothing to post.
    static func sanitize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxLength))
    }
}

// MARK: - CloudKit Conversion

extension ActivityComment {
    static let recordType = "ActivityComment"

    init?(from record: CKRecord) {
        guard let commentIDString = record["commentID"] as? String,
              let commentID = UUID(uuidString: commentIDString),
              let activityIDString = record["activityID"] as? String,
              let activityID = UUID(uuidString: activityIDString),
              let authorID = record["authorID"] as? String,
              let text = record["text"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        self.id = commentID
        self.activityID = activityID
        self.authorID = authorID
        self.authorName = record["authorName"] as? String ?? "Someone"
        self.authorPhotoID = record["authorPhotoID"] as? String
        self.authorEmoji = record["authorEmoji"] as? String
        self.text = text
        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record["commentID"] = id.uuidString
        record["activityID"] = activityID.uuidString
        record["authorID"] = authorID
        record["authorName"] = authorName
        record["authorPhotoID"] = authorPhotoID
        record["authorEmoji"] = authorEmoji
        record["text"] = text
        record["createdAt"] = createdAt
        return record
    }
}
