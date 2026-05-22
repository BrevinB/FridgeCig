import SwiftUI

struct DataPrivacySection: View {
    @EnvironmentObject var purchaseService: PurchaseService

    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingDeleteError: Bool
    @Binding var deleteErrorMessage: String
    @Binding var isDeletingAccount: Bool

    let onExport: () -> Void

    var body: some View {
        Section {
            Button(action: onExport) {
                SettingsRow(icon: "square.and.arrow.up", tint: .blue, title: "Export My Data")
            }

            Button {
                Task {
                    do {
                        try await purchaseService.restorePurchases()
                    } catch {
                        deleteErrorMessage = "Restore failed: \(error.localizedDescription)"
                        showingDeleteError = true
                    }
                }
            } label: {
                SettingsRow(icon: "arrow.clockwise", tint: .green, title: "Restore Purchases")
            }

            NavigationLink {
                BlockedUsersView()
            } label: {
                HStack(spacing: 14) {
                    SettingsIconBadge(systemImage: "hand.raised", tint: .orange)
                    Text("Blocked Users").fontWeight(.medium)
                }
            }

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.2), Color.red.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        if isDeletingAccount {
                            ProgressView()
                                .tint(.red)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account & Data")
                            .fontWeight(.medium)
                        Text("Permanently delete all your data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(isDeletingAccount)
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Export your data in JSON format. Deleting your account removes all drinks, badges, social connections, and profile data from our servers.")
        }
    }
}

#if DEBUG
private struct DataPrivacyPreviewWrapper: View {
    @State private var showConfirm = false
    @State private var showError = false
    @State private var errMsg = ""
    @State private var deleting = false
    var body: some View {
        NavigationStack {
            List {
                DataPrivacySection(
                    showingDeleteConfirmation: $showConfirm,
                    showingDeleteError: $showError,
                    deleteErrorMessage: $errMsg,
                    isDeletingAccount: $deleting,
                    onExport: {}
                )
            }
        }
    }
}

#Preview { DataPrivacyPreviewWrapper().withPreviewEnvironment() }
#endif
