import Foundation
import CloudKit
import Combine
import UIKit
import os

@MainActor
class GlobalFeedService: ObservableObject {
    @Published var items: [ActivityItem] = []
    @Published var isLoading = false
    @Published var hasMore = true

    private let cloudKitManager: CloudKitManager
    private var cursor: CKQueryOperation.Cursor?
    private var blockedUserIDs: Set<String> = []
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private var lastRefreshDate: Date?
    private let freshnessWindow: TimeInterval = 30

    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }

    /// Subscribe to cheers updates from ActivityFeedService
    func observeCheersUpdates(from activityService: ActivityFeedService) {
        activityService.cheersUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (activityID, newCount, newUserIDs) in
                guard let self else { return }
                if let index = self.items.firstIndex(where: { $0.id == activityID }) {
                    self.items[index].cheersCount = newCount
                    self.items[index].cheersUserIDs = newUserIDs
                }
            }
            .store(in: &cancellables)
    }

    func configure(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
    }

    func refresh(force: Bool = false) async {
        if !force, !items.isEmpty,
           let lastDate = lastRefreshDate,
           Date().timeIntervalSince(lastDate) < freshnessWindow {
            return
        }
        cursor = nil
        items = []
        hasMore = true
        await loadMore()
        lastRefreshDate = Date()
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let predicate = NSPredicate(format: "isGlobalPhoto == 1")
            let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

            let result = try await cloudKitManager.fetchFromPublicWithCursor(
                recordType: ActivityItem.recordType,
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                limit: pageSize,
                cursor: cursor
            )

            cursor = result.cursor
            hasMore = result.cursor != nil

            let existingIDs = Set(items.map { $0.id })
            let newItems = result.records
                .compactMap { ActivityItem(from: $0) }
                .filter { !blockedUserIDs.contains($0.userID) && !existingIDs.contains($0.id) }

            items.append(contentsOf: newItems)
        } catch {
            AppLogger.activity.error("Failed to fetch global feed: \(error.localizedDescription)")
            hasMore = false
        }
    }

    func fetchPhoto(recordName: String) async -> UIImage? {
        do {
            let recordID = CKRecord.ID(recordName: recordName)
            guard let record = try await cloudKitManager.fetchFromPublic(recordID: recordID),
                  let asset = record["photo"] as? CKAsset,
                  let fileURL = asset.fileURL,
                  let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            AppLogger.activity.error("Failed to fetch global feed photo: \(error.localizedDescription)")
            return nil
        }
    }

    /// Insert a locally-posted item at the top of the feed (optimistic update)
    func insertLocalItem(_ item: ActivityItem) {
        guard item.isGlobalPhoto, !blockedUserIDs.contains(item.userID) else { return }
        // Avoid duplicates
        if !items.contains(where: { $0.id == item.id }) {
            items.insert(item, at: 0)
        }
    }

    func removeItemsFromUser(_ userID: String) {
        items.removeAll { $0.userID == userID }
        blockedUserIDs.insert(userID)
    }
}
