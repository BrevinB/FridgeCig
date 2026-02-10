import SwiftUI

struct SyncErrorBanner: View {
    @EnvironmentObject var store: DrinkStore
    @State private var isDismissed = false

    var body: some View {
        if let error = store.syncError, !isDismissed {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.icloud.fill")
                        .font(.subheadline.bold())

                    Text("Sync issue")
                        .font(.subheadline.bold())

                    Spacer()

                    Button {
                        Task {
                            await store.performSync()
                        }
                    } label: {
                        Text("Retry")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isDismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.orange.opacity(0.9))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
