import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingPermissionAlert = false

    var body: some View {
        List {
            // Authorization Status
            if !notificationService.isAuthorized {
                Section {
                    Button {
                        Task {
                            let granted = await notificationService.requestAuthorization()
                            if !granted {
                                showingPermissionAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.dietCokeRed)
                            Text("Enable Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                    }
                } footer: {
                    Text("Allow notifications to receive alerts for friend requests, cheers, and reminders.")
                }
            }

            // Push Notifications
            Section {
                Toggle(isOn: $notificationService.preferences.friendRequestsEnabled) {
                    Label("Friend Requests", systemImage: "person.badge.plus")
                }

                Toggle(isOn: $notificationService.preferences.friendAcceptedEnabled) {
                    Label("Friend Accepted", systemImage: "person.badge.checkmark")
                }

                Toggle(isOn: $notificationService.preferences.cheersReceivedEnabled) {
                    Label("Cheers Received", systemImage: "hands.clap.fill")
                }

                Toggle(isOn: $notificationService.preferences.friendMilestonesEnabled) {
                    Label("Friend Milestones", systemImage: "trophy.fill")
                }
            } header: {
                Text("Social Notifications")
            } footer: {
                Text("Get notified when friends interact with you or hit milestones.")
            }
            .disabled(!notificationService.isAuthorized)

            // Local Notifications
            Section {
                Toggle(isOn: $notificationService.preferences.streakRemindersEnabled) {
                    Label("Streak Reminders", systemImage: "flame.fill")
                }

                if notificationService.preferences.streakRemindersEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: $notificationService.preferences.streakReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Streak Reminders")
            } footer: {
                Text("Get a reminder in the evening if you haven't logged a drink today.")
            }
            .disabled(!notificationService.isAuthorized)

            Section {
                Toggle(isOn: $notificationService.preferences.dailySummaryEnabled) {
                    Label("Daily Summary", systemImage: "chart.bar.fill")
                }

                if notificationService.preferences.dailySummaryEnabled {
                    DatePicker(
                        "Summary Time",
                        selection: $notificationService.preferences.dailySummaryTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Daily Summary")
            } footer: {
                Text("Get a summary of your day's consumption.")
            }
            .disabled(!notificationService.isAuthorized)

            Section {
                Toggle(isOn: $notificationService.preferences.weeklySummaryEnabled) {
                    Label("Weekly Summary", systemImage: "calendar")
                }

                if notificationService.preferences.weeklySummaryEnabled {
                    DatePicker(
                        "Summary Time",
                        selection: $notificationService.preferences.weeklySummaryTime,
                        displayedComponents: .hourAndMinute
                    )
                    Text("Delivered every Sunday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Weekly Summary")
            } footer: {
                Text("Get a weekly recap of your consumption every Sunday.")
            }
            .disabled(!notificationService.isAuthorized)

            #if DEBUG
            Section {
                Button("Test Friend Request Notification") {
                    Task { await notificationService.testFriendRequestNotification() }
                }

                Button("Test Cheers Notification") {
                    Task { await notificationService.testCheersNotification() }
                }

                Button("Test Friend Milestone Notification") {
                    Task { await notificationService.testFriendMilestoneNotification() }
                }

                Button("Test Streak Reminder") {
                    Task { await notificationService.testStreakReminder() }
                }

                Button("List Pending Notifications") {
                    Task { await notificationService.listPendingNotifications() }
                }

                Button("List CloudKit Subscriptions") {
                    Task { await notificationService.listCloudKitSubscriptions() }
                }
            } header: {
                Text("Debug")
            }
            #endif
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.updateAuthorizationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To enable notifications, please go to Settings and turn on notifications for FridgeCig.")
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(NotificationService(cloudKitManager: CloudKitManager()))
    }
}
