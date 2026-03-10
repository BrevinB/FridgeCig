import Foundation
import CloudKit

struct ContentReport: Identifiable {
    let id: String
    let reportedActivityID: String
    let reportedUserID: String
    let reporterUserID: String
    let reason: ReportReason
    let details: String?
    let timestamp: Date
    let status: ReportStatus

    enum ReportReason: String, CaseIterable {
        case inappropriate
        case spam
        case offensive
        case other

        var displayName: String {
            switch self {
            case .inappropriate: return "Inappropriate"
            case .spam: return "Spam"
            case .offensive: return "Offensive"
            case .other: return "Other"
            }
        }
    }

    enum ReportStatus: String {
        case pending
        case reviewed
        case dismissed
        case actioned
    }

    init(
        reportedActivityID: String,
        reportedUserID: String,
        reporterUserID: String,
        reason: ReportReason,
        details: String? = nil
    ) {
        self.id = UUID().uuidString
        self.reportedActivityID = reportedActivityID
        self.reportedUserID = reportedUserID
        self.reporterUserID = reporterUserID
        self.reason = reason
        self.details = details
        self.timestamp = Date()
        self.status = .pending
    }
}

// MARK: - CloudKit Conversion

extension ContentReport {
    static let recordType = "ContentReport"

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record["reportID"] = id
        record["reportedActivityID"] = reportedActivityID
        record["reportedUserID"] = reportedUserID
        record["reporterUserID"] = reporterUserID
        record["reason"] = reason.rawValue
        record["details"] = details
        record["timestamp"] = timestamp
        record["status"] = status.rawValue
        return record
    }
}
