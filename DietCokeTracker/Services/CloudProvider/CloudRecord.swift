import Foundation

// MARK: - CloudValue

/// Type-safe value type for cloud record fields.
/// Supports the common types shared across CloudKit, Firebase Firestore, and other backends.
enum CloudValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case date(Date)
    case bool(Bool)
    case stringArray([String])
    case data(Data)
    case null

    // MARK: - Convenience Accessors

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let v) = self { return v }
        if case .int(let v) = self { return Double(v) }
        return nil
    }

    var dateValue: Date? {
        if case .date(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        if case .int(let v) = self { return v != 0 }
        return nil
    }

    var stringArrayValue: [String]? {
        if case .stringArray(let v) = self { return v }
        return nil
    }

    var dataValue: Data? {
        if case .data(let v) = self { return v }
        return nil
    }

    var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - CloudRecord

/// A provider-agnostic cloud database record.
///
/// This type abstracts away the differences between CloudKit's `CKRecord`,
/// Firebase Firestore's `DocumentSnapshot`, or any other backend's record format.
/// Models convert to/from `CloudRecord` instead of provider-specific types.
struct CloudRecord: Sendable {
    /// The record type / collection name (e.g., "DrinkEntry", "UserProfile")
    let recordType: String

    /// Unique record identifier (CKRecord.ID.recordName for CloudKit, document ID for Firestore)
    let recordID: String

    /// The record's field values
    var fields: [String: CloudValue]

    /// Server-assigned creation date (if available)
    var creationDate: Date?

    init(recordType: String, recordID: String = UUID().uuidString, fields: [String: CloudValue] = [:], creationDate: Date? = nil) {
        self.recordType = recordType
        self.recordID = recordID
        self.fields = fields
        self.creationDate = creationDate
    }

    // MARK: - Subscript Access

    subscript(key: String) -> CloudValue? {
        get { fields[key] }
        set { fields[key] = newValue }
    }
}

// MARK: - Query Types

/// A filter condition for querying cloud records.
enum QueryFilter: Sendable {
    /// Field equals a value (e.g., `userID == "abc"`)
    case equals(field: String, value: CloudValue)

    /// Field value is in a set (e.g., `userID IN ["a", "b", "c"]`)
    case containedIn(field: String, values: [String])

    /// String field begins with prefix (e.g., `username BEGINSWITH "john"`)
    case beginsWith(field: String, prefix: String)
}

/// Sort direction for query results.
struct QuerySort: Sendable {
    let field: String
    let ascending: Bool

    init(_ field: String, ascending: Bool = true) {
        self.field = field
        self.ascending = ascending
    }
}
