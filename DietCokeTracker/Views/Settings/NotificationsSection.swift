import SwiftUI

struct NotificationsSection: View {
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        Section {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack(spacing: 14) {
                    SettingsIconBadge(
                        systemImage: notificationService.isAuthorized ? "bell.fill" : "bell",
                        tint: .dietCokeRed
                    )

                    Text("Notifications")
                        .fontWeight(.medium)

                    Spacer()

                    if !notificationService.isAuthorized {
                        Text("Off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Notifications")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List { NotificationsSection() }
    }
    .withPreviewEnvironment()
}
#endif
