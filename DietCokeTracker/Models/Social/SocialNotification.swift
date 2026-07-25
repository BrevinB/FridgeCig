import Foundation
import SwiftUI
import CloudKit

// MARK: - Kind

enum SocialNotificationKind: String, Codable, CaseIterable {
    case reaction
    case comment
    case friendRequest
    case friendAccepted
    case nudge

    var icon: String {
        switch self {
        case .reaction: return "hands.clap.fill"
        case .comment: return "bubble.left.fill"
        case .friendRequest: return "person.badge.plus"
        case .friendAccepted: return "person.2.fill"
        case .nudge: return "hand.wave.fill"
        }
    }

    var color: Color {
        switch self {
        case .reaction: return .orange
        case .comment: return .blue
        case .friendRequest: return .purple
        case .friendAccepted: return .green
        case .nudge: return .dietCokeRed
        }
    }

    /// Where a tap on this notification should land.
    var destination: SocialNotificationDestination {
        switch self {
        case .reaction, .comment: return .feed
        case .friendRequest, .friendAccepted: return .friends
        case .nudge: return .logDrink
        }
    }
}

enum SocialNotificationDestination {
    case feed
    case friends
    case logDrink
}

// MARK: - Social Notification

/// An inbox entry written by whoever performed the action, addressed to the
/// person it happened to. Doubles as the push trigger: a single CloudKit
/// subscription on `recipientID` covers every social event, so pushes carry the
/// actor's real name instead of a generic "someone did something".
struct SocialNotification: Identifiable, Equatable {
    let id: UUID
    let recipientID: String
    let actorID: String
    var actorName: String
    var actorPhotoID: String?
    var actorEmoji: String?
    let kind: SocialNotificationKind
    var activityID: UUID?
    /// Reaction emoji, comment text, or nudge message — whatever gives the
    /// event its specifics.
    var detail: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        recipientID: String,
        actorID: String,
        actorName: String,
        actorPhotoID: String? = nil,
        actorEmoji: String? = nil,
        kind: SocialNotificationKind,
        activityID: UUID? = nil,
        detail: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.recipientID = recipientID
        self.actorID = actorID
        self.actorName = actorName
        self.actorPhotoID = actorPhotoID
        self.actorEmoji = actorEmoji
        self.kind = kind
        self.activityID = activityID
        self.detail = detail
        self.createdAt = createdAt
    }

    /// The sentence shown in the inbox and pushed as the notification body.
    /// Stored on the record so a push can render it without a fetch.
    var body: String {
        switch kind {
        case .reaction:
            let emoji = detail.flatMap { ReactionEmoji(rawValue: $0) } ?? .legacyDefault
            return "\(emoji.verb) your post \(emoji.rawValue)"
        case .comment:
            if let text = detail, !text.isEmpty {
                return "commented: \"\(text)\""
            }
            return "commented on your post"
        case .friendRequest:
            return "wants to be your friend"
        case .friendAccepted:
            return "accepted your friend request"
        case .nudge:
            if let text = detail, !text.isEmpty {
                return text
            }
            return "is wondering where your Diet Coke is 🥤"
        }
    }

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - CloudKit Conversion

extension SocialNotification {
    static let recordType = "SocialNotification"

    /// Inbox entries older than this stop being fetched, keeping the query
    /// bounded as a user's history grows.
    static let retentionWindow: TimeInterval = 60 * 60 * 24 * 30

    init?(from record: CKRecord) {
        guard let notificationIDString = record["notificationID"] as? String,
              let notificationID = UUID(uuidString: notificationIDString),
              let recipientID = record["recipientID"] as? String,
              let actorID = record["actorID"] as? String,
              let kindRaw = record["kind"] as? String,
              let kind = SocialNotificationKind(rawValue: kindRaw),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        self.id = notificationID
        self.recipientID = recipientID
        self.actorID = actorID
        self.actorName = record["actorName"] as? String ?? "Someone"
        self.actorPhotoID = record["actorPhotoID"] as? String
        self.actorEmoji = record["actorEmoji"] as? String
        self.kind = kind
        self.activityID = (record["activityID"] as? String).flatMap { UUID(uuidString: $0) }
        self.detail = record["detail"] as? String
        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record["notificationID"] = id.uuidString
        record["recipientID"] = recipientID
        record["actorID"] = actorID
        record["actorName"] = actorName
        record["actorPhotoID"] = actorPhotoID
        record["actorEmoji"] = actorEmoji
        record["kind"] = kind.rawValue
        record["activityID"] = activityID?.uuidString
        record["detail"] = detail
        record["createdAt"] = createdAt
        // Denormalized so the push subscription can substitute it straight into
        // the alert body without fetching the record first.
        record["bodyText"] = body
        return record
    }
}
