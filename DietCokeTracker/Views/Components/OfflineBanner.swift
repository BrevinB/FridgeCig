import SwiftUI

/// Banner displayed when the device is offline
struct OfflineBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var offlineQueue: OfflineQueue
    @State private var isExpanded = false

    var body: some View {
        if !networkMonitor.isConnected {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.subheadline.bold())

                        Text("You're offline")
                            .font(.subheadline.bold())

                        Spacer()

                        if offlineQueue.hasPendingOperations {
                            HStack(spacing: 4) {
                                Text("\(offlineQueue.pendingCount)")
                                    .font(.caption.bold())
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Changes you make will be saved locally and synced when you're back online.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        if offlineQueue.hasPendingOperations {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("\(offlineQueue.pendingCount) pending \(offlineQueue.pendingCount == 1 ? "change" : "changes") to sync")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color.gray.opacity(0.9))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

/// Modifier to add offline banner to any view
struct OfflineBannerModifier: ViewModifier {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineBanner()
            content
        }
        .animation(.spring(response: 0.3), value: networkMonitor.isConnected)
    }
}

extension View {
    func withOfflineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}

/// Compact inline indicator for use in specific views
struct OfflineIndicator: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash")
                    .font(.caption2)
                Text("Offline")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack {
        OfflineBanner()
        Spacer()
        OfflineIndicator()
        Spacer()
    }
    .environmentObject(NetworkMonitor.shared)
    .environmentObject(OfflineQueue.shared)
}
