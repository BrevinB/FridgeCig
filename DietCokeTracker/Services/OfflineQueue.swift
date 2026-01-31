import Foundation

/// Queues operations that failed due to network issues for later retry
@MainActor
class OfflineQueue: ObservableObject {
    static let shared = OfflineQueue()

    @Published private(set) var pendingOperations: [PendingOperation] = []
    @Published private(set) var isProcessing = false

    private let storageKey = "OfflineQueueOperations"
    private var networkObserver: NSObjectProtocol?

    struct PendingOperation: Codable, Identifiable {
        let id: UUID
        let type: OperationType
        let payload: Data
        let timestamp: Date
        var retryCount: Int

        init(type: OperationType, payload: Data) {
            self.id = UUID()
            self.type = type
            self.payload = payload
            self.timestamp = Date()
            self.retryCount = 0
        }
    }

    enum OperationType: String, Codable {
        case syncDrink
        case postActivity
        case sendFriendRequest
        case acceptFriendRequest
        case sendCheer
        case syncBadge
    }

    private init() {
        loadPendingOperations()
        setupNetworkObserver()
    }

    // MARK: - Queue Management

    func enqueue(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }

    func enqueue(type: OperationType, payload: Encodable) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let operation = PendingOperation(type: type, payload: data)
        enqueue(operation)
    }

    func remove(_ operation: PendingOperation) {
        pendingOperations.removeAll { $0.id == operation.id }
        savePendingOperations()
    }

    func clear() {
        pendingOperations.removeAll()
        savePendingOperations()
    }

    var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }

    var pendingCount: Int {
        pendingOperations.count
    }

    // MARK: - Processing

    func processQueue(networkMonitor: NetworkMonitor, using processor: @escaping (PendingOperation) async -> Bool) async {
        guard !isProcessing else { return }
        guard networkMonitor.isConnected else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Process operations in order
        var operationsToRemove: [UUID] = []
        var operationsToUpdate: [(UUID, Int)] = []

        for operation in pendingOperations {
            // Check network before each operation
            guard networkMonitor.isConnected else { break }

            let success = await processor(operation)

            if success {
                operationsToRemove.append(operation.id)
            } else {
                // Increment retry count
                let newRetryCount = operation.retryCount + 1
                if newRetryCount >= 5 {
                    // Max retries reached, remove from queue
                    operationsToRemove.append(operation.id)
                } else {
                    operationsToUpdate.append((operation.id, newRetryCount))
                }
            }
        }

        // Update state
        for id in operationsToRemove {
            pendingOperations.removeAll { $0.id == id }
        }
        for (id, retryCount) in operationsToUpdate {
            if let index = pendingOperations.firstIndex(where: { $0.id == id }) {
                pendingOperations[index].retryCount = retryCount
            }
        }

        savePendingOperations()
    }

    // MARK: - Persistence

    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let operations = try? JSONDecoder().decode([PendingOperation].self, from: data) else {
            return
        }
        pendingOperations = operations
    }

    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Network Observer

    private func setupNetworkObserver() {
        networkObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("networkBecameAvailable"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard self != nil else { return }
                // Notify that queue should be processed
                NotificationCenter.default.post(name: .offlineQueueReadyToProcess, object: nil)
            }
        }
    }

    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineQueueReadyToProcess = Notification.Name("offlineQueueReadyToProcess")
}
