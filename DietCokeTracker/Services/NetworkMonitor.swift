import Foundation
import Network
import Combine

/// Monitors network connectivity and provides real-time status updates
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }

        // Notify when connection status changes
        if wasConnected != isConnected {
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["isConnected": isConnected]
            )

            if isConnected {
                // Trigger sync when coming back online
                NotificationCenter.default.post(name: .networkBecameAvailable, object: nil)
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let networkBecameAvailable = Notification.Name("networkBecameAvailable")
}
