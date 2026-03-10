import SwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.colorScheme) private var colorScheme

    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.dietCokeRed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blockedUsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.dietCokeDarkSilver)
                    Text("No Blocked Users")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)
                    Text("Users you block will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .fontWeight(.medium)
                                    .foregroundColor(.dietCokeCharcoal)
                            }

                            Spacer()

                            Button("Unblock") {
                                Task {
                                    await unblockUser(user)
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeRed)
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBlockedUsers()
        }
    }

    private func loadBlockedUsers() async {
        guard let userID = identityService.currentIdentity?.userIDString else {
            isLoading = false
            return
        }
        do {
            blockedUsers = try await friendService.fetchBlockedUsers(forUserID: userID)
        } catch {
            AppLogger.friends.error("Failed to load blocked users: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func unblockUser(_ user: BlockedUser) async {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return }
        do {
            try await friendService.unblockUser(blockerID: currentUserID, targetID: user.userID)
            blockedUsers.removeAll { $0.userID == user.userID }
        } catch {
            AppLogger.friends.error("Failed to unblock user: \(error.localizedDescription)")
        }
    }
}
