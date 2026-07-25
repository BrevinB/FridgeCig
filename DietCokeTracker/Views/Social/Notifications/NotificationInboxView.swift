import SwiftUI

/// The social inbox — everything other people did to you, in one place.
///
/// Without this, a reaction or comment only exists as a push that vanishes when
/// dismissed. This is the screen that makes coming back worth it.
struct NotificationInboxView: View {
    @EnvironmentObject private var socialNotifications: SocialNotificationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    /// Called when the user taps a notification that should navigate somewhere.
    private let onNavigate: ((SocialNotificationDestination) -> Void)?

    init(onNavigate: ((SocialNotificationDestination) -> Void)? = nil) {
        self.onNavigate = onNavigate
    }

    private struct InboxSection: Identifiable {
        let title: String
        let items: [SocialNotification]

        var id: String { title }
    }

    private var grouped: [InboxSection] {
        let calendar = Calendar.current
        let now = Date()
        var today: [SocialNotification] = []
        var week: [SocialNotification] = []
        var earlier: [SocialNotification] = []

        for notification in socialNotifications.notifications {
            if calendar.isDateInToday(notification.createdAt) {
                today.append(notification)
            } else if let days = calendar.dateComponents([.day], from: notification.createdAt, to: now).day, days < 7 {
                week.append(notification)
            } else {
                earlier.append(notification)
            }
        }

        return [
            InboxSection(title: "Today", items: today),
            InboxSection(title: "This Week", items: week),
            InboxSection(title: "Earlier", items: earlier)
        ].filter { !$0.items.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Group {
                if socialNotifications.isLoading && socialNotifications.notifications.isEmpty {
                    loadingState
                } else if socialNotifications.notifications.isEmpty {
                    emptyState
                } else {
                    inboxList
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if socialNotifications.unreadCount > 0 {
                        Button("Mark All Read") {
                            withAnimation {
                                socialNotifications.markAllRead()
                            }
                        }
                        .font(.subheadline)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await socialNotifications.refresh()
            }
            .refreshable {
                await socialNotifications.refresh(force: true)
            }
            .onDisappear {
                // Seeing the list counts as reading it.
                socialNotifications.markAllRead()
            }
        }
    }

    // MARK: - List

    private var inboxList: some View {
        List {
            ForEach(grouped) { section in
                Section(section.title) {
                    ForEach(section.items) { notification in
                        Button {
                            handleTap(notification)
                        } label: {
                            NotificationRow(
                                notification: notification,
                                isUnread: socialNotifications.isUnread(notification)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            socialNotifications.isUnread(notification)
                                ? Color.dietCokeRed.opacity(colorScheme == .dark ? 0.12 : 0.06)
                                : Color.clear
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.dietCokeRed)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.badge")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.dietCokeRed)
            }

            VStack(spacing: 8) {
                Text("Nothing Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Reactions, comments, and nudges\nfrom your friends land here.")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func handleTap(_ notification: SocialNotification) {
        socialNotifications.markRead(notification)
        HapticManager.lightImpact()
        dismiss()
        onNavigate?(notification.kind.destination)
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: SocialNotification
    let isUnread: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: notification.actorName,
                    profilePhotoID: notification.actorPhotoID,
                    profileEmoji: notification.actorEmoji,
                    size: 44
                )

                Image(systemName: notification.kind.icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(notification.kind.color))
                    .overlay(Circle().stroke(Color.dietCokeCardBackground, lineWidth: 1.5))
                    .offset(x: 3, y: 3)
            }

            VStack(alignment: .leading, spacing: 3) {
                (Text(notification.actorName).fontWeight(.semibold)
                    + Text(" ")
                    + Text(notification.body))
                    .font(.subheadline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(notification.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .multilineTextAlignment(.leading)

            Spacer(minLength: 4)

            if isUnread {
                Circle()
                    .fill(Color.dietCokeRed)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Inbox Bell

/// Toolbar bell with an unread badge.
struct InboxBellButton: View {
    @EnvironmentObject private var socialNotifications: SocialNotificationService

    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: socialNotifications.unreadCount > 0 ? "bell.badge.fill" : "bell")
                    .font(.system(size: 17, weight: .medium))
                    .symbolRenderingMode(socialNotifications.unreadCount > 0 ? .palette : .monochrome)
                    .foregroundStyle(Color.dietCokeRed, Color.dietCokeCharcoal)
                    .frame(width: 24, height: 24)

                if socialNotifications.unreadCount > 0 {
                    Text(socialNotifications.unreadCount > 9 ? "9+" : "\(socialNotifications.unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Circle().fill(Color.dietCokeRed))
                        .offset(x: 8, y: -6)
                }
            }
        }
        .accessibilityLabel(
            socialNotifications.unreadCount > 0
                ? "Activity, \(socialNotifications.unreadCount) unread"
                : "Activity"
        )
    }
}

#if DEBUG
#Preview {
    NotificationInboxView()
        .withPreviewEnvironment()
}
#endif
