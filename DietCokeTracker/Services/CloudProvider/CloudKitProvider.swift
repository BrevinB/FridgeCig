import Foundation
import CloudKit
import os

/// CloudKit implementation of `CloudProvider`.
///
/// Wraps Apple's CloudKit APIs to provide the same interface that a Firebase
/// or custom backend would implement. This is the production provider for iOS users.
@MainActor
class CloudKitProvider: ObservableObject, CloudProvider {
    static let containerID = "iCloud.co.brevinb.fridgecig"

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase

    @Published var isAvailable = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    init() {
        container = CKContainer(identifier: Self.containerID)
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            isAvailable = (status == .available)
        } catch {
            accountStatus = .couldNotDetermine
            isAvailable = false
        }
    }

    // MARK: - Private Database

    @discardableResult
    func saveToPrivate(_ record: CloudRecord) async throws -> CloudRecord {
        let ckRecord = record.toCKRecord()
        let (saveResults, _) = try await privateDatabase.modifyRecords(
            saving: [ckRecord],
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, result) in saveResults {
            if case .failure(let error) = result {
                throw error
            }
        }

        return CloudRecord(from: ckRecord)
    }

    func fetchFromPrivate(recordType: String) async throws -> [CloudRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await privateDatabase.records(matching: query, resultsLimit: 500)
            return results.compactMap { try? $0.1.get() }.map { CloudRecord(from: $0) }
        } catch let error as CKError where error.code == .unknownItem {
            return []
        } catch let error as CKError where error.code == .invalidArguments {
            return try await fetchAllFromPrivateZone(recordType: recordType)
        }
    }

    func deleteFromPrivate(recordID: String) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        try await privateDatabase.deleteRecord(withID: ckRecordID)
    }

    // MARK: - Public Database

    @discardableResult
    func saveToPublic(_ record: CloudRecord) async throws -> CloudRecord {
        let ckRecord = record.toCKRecord()
        let (saveResults, _) = try await publicDatabase.modifyRecords(
            saving: [ckRecord],
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, result) in saveResults {
            switch result {
            case .success(let savedRecord):
                return CloudRecord(from: savedRecord)
            case .failure(let error):
                throw error
            }
        }

        throw CKError(.unknownItem)
    }

    func fetchFromPublic(
        recordType: String,
        filters: [QueryFilter],
        sorts: [QuerySort],
        limit: Int
    ) async throws -> [CloudRecord] {
        let predicate = buildPredicate(from: filters)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        if !sorts.isEmpty {
            query.sortDescriptors = sorts.map {
                NSSortDescriptor(key: $0.field, ascending: $0.ascending)
            }
        }

        do {
            let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: limit)
            return results.compactMap { try? $0.1.get() }.map { CloudRecord(from: $0) }
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
    }

    func fetchFromPublic(recordID: String, recordType: String) async throws -> CloudRecord? {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        do {
            let record = try await publicDatabase.record(for: ckRecordID)
            return CloudRecord(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func deleteFromPublic(recordID: String) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        try await publicDatabase.deleteRecord(withID: ckRecordID)
    }

    // MARK: - Assets

    func uploadAsset(_ data: Data, recordType: String, fieldName: String) async throws -> String {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("dat")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let asset = CKAsset(fileURL: tempURL)
        let record = CKRecord(recordType: recordType)
        record[fieldName] = asset
        record["uploadedAt"] = Date()

        let (saveResults, _) = try await publicDatabase.modifyRecords(
            saving: [record],
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, result) in saveResults {
            switch result {
            case .success(let saved):
                return saved.recordID.recordName
            case .failure(let error):
                throw error
            }
        }

        throw CKError(.unknownItem)
    }

    func downloadAsset(recordID: String, fieldName: String) async throws -> Data? {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        do {
            let record = try await publicDatabase.record(for: ckRecordID)
            guard let asset = record[fieldName] as? CKAsset,
                  let fileURL = asset.fileURL else {
                return nil
            }
            return try Data(contentsOf: fileURL)
        } catch {
            return nil
        }
    }

    // MARK: - Subscriptions

    @discardableResult
    func subscribe(
        to recordType: String,
        filters: [QueryFilter],
        subscriptionID: String
    ) async -> Bool {
        guard isAvailable else { return false }

        let predicate = buildPredicate(from: filters)
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            try await publicDatabase.save(subscription)
            return true
        } catch let error as CKError where error.code == .serverRejectedRequest {
            do {
                try await publicDatabase.deleteSubscription(withID: subscriptionID)
                try await publicDatabase.save(subscription)
                return true
            } catch {
                AppLogger.cloudKit.error("Failed to update subscription \(subscriptionID): \(error.localizedDescription)")
                return false
            }
        } catch {
            AppLogger.cloudKit.error("Failed to create subscription \(subscriptionID): \(error.localizedDescription)")
            return false
        }
    }

    func unsubscribe(subscriptionID: String) async {
        do {
            try await publicDatabase.deleteSubscription(withID: subscriptionID)
        } catch let error as CKError where error.code == .unknownItem {
            // Already removed
        } catch {
            AppLogger.cloudKit.error("Failed to remove subscription \(subscriptionID): \(error.localizedDescription)")
        }
    }

    // MARK: - Friend Code Generation

    static func generateFriendCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    // MARK: - Private Helpers

    private func fetchAllFromPrivateZone(recordType: String) async throws -> [CloudRecord] {
        let zoneID = CKRecordZone.default().zoneID
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))

        do {
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID, resultsLimit: 500)
            return results.compactMap { try? $0.1.get() }.map { CloudRecord(from: $0) }
        } catch {
            AppLogger.cloudKit.error("Failed to fetch from private zone: \(error.localizedDescription)")
            return []
        }
    }

    private func buildPredicate(from filters: [QueryFilter]) -> NSPredicate {
        guard !filters.isEmpty else {
            return NSPredicate(value: true)
        }

        let predicates = filters.map { filter -> NSPredicate in
            switch filter {
            case .equals(let field, let value):
                switch value {
                case .string(let v):
                    return NSPredicate(format: "%K == %@", field, v)
                case .int(let v):
                    return NSPredicate(format: "%K == %d", field, v)
                case .double(let v):
                    return NSPredicate(format: "%K == %f", field, v)
                case .bool(let v):
                    // CloudKit stores bools as Int (0/1)
                    return NSPredicate(format: "%K == %d", field, v ? 1 : 0)
                case .date(let v):
                    return NSPredicate(format: "%K == %@", field, v as NSDate)
                default:
                    return NSPredicate(value: true)
                }

            case .containedIn(let field, let values):
                return NSPredicate(format: "%K IN %@", field, values)

            case .beginsWith(let field, let prefix):
                return NSPredicate(format: "%K BEGINSWITH %@", field, prefix)
            }
        }

        if predicates.count == 1 {
            return predicates[0]
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

// MARK: - CKRecord <-> CloudRecord Bridging

extension CloudRecord {
    /// Create a CloudRecord from a CKRecord.
    init(from ckRecord: CKRecord) {
        self.recordType = ckRecord.recordType
        self.recordID = ckRecord.recordID.recordName
        self.creationDate = ckRecord.creationDate

        var fields: [String: CloudValue] = [:]
        for key in ckRecord.allKeys() {
            guard let value = ckRecord[key] else { continue }
            if let s = value as? String {
                fields[key] = .string(s)
            } else if let n = value as? NSNumber {
                // Distinguish between Int and Double
                let objCType = String(cString: n.objCType)
                if objCType == "d" || objCType == "f" {
                    fields[key] = .double(n.doubleValue)
                } else {
                    fields[key] = .int(n.intValue)
                }
            } else if let d = value as? Date {
                fields[key] = .date(d)
            } else if let arr = value as? [String] {
                fields[key] = .stringArray(arr)
            } else if let asset = value as? CKAsset, let url = asset.fileURL,
                      let data = try? Data(contentsOf: url) {
                fields[key] = .data(data)
            }
        }
        self.fields = fields
    }

    /// Convert to a CKRecord for saving to CloudKit.
    func toCKRecord() -> CKRecord {
        let ckRecord: CKRecord
        if recordID.isEmpty || UUID(uuidString: recordID) != nil {
            // New record or auto-generated ID — let CloudKit assign the ID
            ckRecord = CKRecord(recordType: recordType)
        } else {
            // Existing record — preserve the ID for updates
            ckRecord = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: recordID))
        }

        for (key, value) in fields {
            switch value {
            case .string(let v): ckRecord[key] = v as CKRecordValue
            case .int(let v): ckRecord[key] = v as CKRecordValue
            case .double(let v): ckRecord[key] = v as CKRecordValue
            case .date(let v): ckRecord[key] = v as CKRecordValue
            case .bool(let v): ckRecord[key] = (v ? 1 : 0) as CKRecordValue
            case .stringArray(let v):
                if !v.isEmpty { ckRecord[key] = v as CKRecordValue }
            case .data, .null:
                break // Assets handled separately, nulls skipped
            }
        }

        return ckRecord
    }
}
