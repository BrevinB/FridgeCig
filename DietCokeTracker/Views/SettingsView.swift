import SwiftUI

struct SettingsView: View {
    /// When `true`, the view hides the "Done" toolbar button — used when the
    /// view is hosted inside a tab rather than presented as a sheet.
    var hidesDoneButton: Bool = false

    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeletingAccount = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var showingHealthKitPaywall = false

    var body: some View {
        NavigationStack {
            List {
                SubscriptionSection()
                NotificationsSection()
                AppearanceSection()
                HealthSection(showingHealthKitPaywall: $showingHealthKitPaywall)
                DefaultBeverageSection()
                DataPrivacySection(
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    showingDeleteError: $showingDeleteError,
                    deleteErrorMessage: $deleteErrorMessage,
                    isDeletingAccount: $isDeletingAccount,
                    onExport: exportUserData
                )
                SupportSection()
                #if DEBUG
                DebugSection()
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !hidesDoneButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .confirmationDialog(
                "Delete Account?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) { deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data including drink history, badges, friends, and profile. This action cannot be undone.")
            }
            .alert("Error Deleting Account", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ExportDataSheet(data: data)
                }
            }
            .sheet(isPresented: $showingHealthKitPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Export Data

    private func exportUserData() {
        var exportDict: [String: Any] = [:]

        exportDict["preferences"] = preferences.exportAllData()

        let entriesData = store.entries.map { entry -> [String: Any] in
            var dict: [String: Any] = [
                "id": entry.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: entry.timestamp),
                "type": entry.type.rawValue,
                "brand": entry.brand.rawValue,
                "ounces": entry.ounces
            ]
            if let rating = entry.rating {
                dict["rating"] = rating.rawValue
            }
            return dict
        }
        exportDict["drinkEntries"] = entriesData
        exportDict["totalDrinks"] = store.entries.count
        exportDict["totalOunces"] = store.entries.reduce(0) { $0 + $1.ounces }

        if let identity = identityService.currentIdentity {
            exportDict["userIdentity"] = [
                "friendCode": identity.friendCode,
                "createdAt": ISO8601DateFormatter().string(from: identity.createdAt)
            ]
        }

        exportDict["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportDict["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
            exportData = jsonData
            showingExportSheet = true
        }
    }

    // MARK: - Delete Account

    private func deleteAccount() {
        isDeletingAccount = true

        let preferencesRef = preferences
        let storeRef = store
        let friendServiceRef = friendService
        let activityServiceRef = activityService
        let deletion = AccountDeletionService(cloudKitManager: cloudKitManager)

        Task {
            do {
                guard let userID = identityService.currentIdentity?.userIDString else {
                    throw NSError(
                        domain: "FridgeCig",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No user identity found"]
                    )
                }

                try await deletion.deleteAccount(userID: userID) {
                    preferencesRef.clearAllData()
                    storeRef.clearAllData()
                    friendServiceRef.clearAllData()
                    activityServiceRef.clearAllData()
                }

                await MainActor.run {
                    isDeletingAccount = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    deleteErrorMessage = error.localizedDescription
                    showingDeleteError = true
                    isDeletingAccount = false
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    SettingsView().withPreviewEnvironment()
}
#endif
