import Foundation
import CloudKit

/// Tears down all CloudKit-side and local user data for account deletion.
/// Extracted from SettingsView so the view can stay focused on UI.
@MainActor
struct AccountDeletionService {
    let cloudKitManager: CloudKitManager

    func deleteAccount(
        userID: String,
        clearLocal: @MainActor @Sendable () -> Void
    ) async throws {
        try await deleteUserProfile(userID: userID)
        try await deleteAllDrinkEntries(userID: userID)
        try await deleteAllFriendConnections(userID: userID)
        try await deleteAllActivityItemsAndPhotos(userID: userID)
        try await deleteAllProfilePhotos(userID: userID)
        try await deleteAllContentReports(userID: userID)
        try await deletePrivateCloudData()
        ProfilePhotoCache.shared.clearAll()
        clearLocal()
    }

    private func deleteUserProfile(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "UserProfile",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1
        )
        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllDrinkEntries(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "DrinkEntry",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1000
        )
        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllFriendConnections(userID: String) async throws {
        let requesterRecords = try await cloudKitManager.fetchFromPublic(
            recordType: "FriendConnection",
            predicate: NSPredicate(format: "requesterID == %@", userID),
            limit: 500
        )
        for record in requesterRecords {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }

        let targetRecords = try await cloudKitManager.fetchFromPublic(
            recordType: "FriendConnection",
            predicate: NSPredicate(format: "targetID == %@", userID),
            limit: 500
        )
        for record in targetRecords {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllActivityItemsAndPhotos(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "ActivityItem",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1000
        )

        var photoRecordNames: [String] = []
        for record in records {
            if let payloadJSON = record["payloadJSON"] as? String,
               let data = payloadJSON.data(using: .utf8),
               let payload = try? JSONDecoder().decode(ActivityPayload.self, from: data),
               let photoURL = payload.photoURL {
                photoRecordNames.append(photoURL)
            }
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }

        let privateRecords = (try? await cloudKitManager.fetchFromPrivate(recordType: "ActivityItem")) ?? []
        for record in privateRecords {
            try? await cloudKitManager.deleteFromPrivate(recordID: record.recordID)
        }

        for recordName in photoRecordNames {
            let recordID = CKRecord.ID(recordName: recordName)
            try? await cloudKitManager.deleteFromPublic(recordID: recordID)
        }
    }

    private func deleteAllProfilePhotos(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "ProfilePhoto",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 100
        )
        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllContentReports(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "ContentReport",
            predicate: NSPredicate(format: "reporterUserID == %@", userID),
            limit: 500
        )
        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deletePrivateCloudData() async throws {
        let identityRecords = try await cloudKitManager.fetchFromPrivate(recordType: "UserIdentity")
        for record in identityRecords {
            try await cloudKitManager.deleteFromPrivate(recordID: record.recordID)
        }
        let badgeRecords = try await cloudKitManager.fetchFromPrivate(recordType: "BadgeData")
        for record in badgeRecords {
            try await cloudKitManager.deleteFromPrivate(recordID: record.recordID)
        }
    }
}
