import SwiftUI

struct FriendDetailView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.dismiss) private var dismiss

    let friend: UserProfile
    @State private var showingRemoveAlert = false
    @State private var isRemoving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.dietCokeRed.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Text(friend.displayName.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.dietCokeRed)
                    }

                    // Name
                    Text(friend.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dietCokeCharcoal)

                    // Username if available
                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.dietCokeCardBackground)
                .cornerRadius(16)

                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.dietCokeRed)
                        Text("Stats")
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        FriendStatCard(title: "Current Streak", value: "\(friend.currentStreak)", icon: "flame.fill", color: .orange)
                        FriendStatCard(title: "This Week", value: "\(friend.weeklyDrinks)", icon: "calendar", color: .blue)
                        FriendStatCard(title: "This Month", value: "\(friend.monthlyDrinks)", icon: "calendar.badge.clock", color: .purple)
                        FriendStatCard(title: "All Time", value: "\(friend.allTimeDrinks)", icon: "cup.and.saucer.fill", color: .dietCokeRed)
                    }
                }
                .padding(16)
                .background(Color.dietCokeCardBackground)
                .cornerRadius(16)

                // Remove Friend Button
                Button {
                    showingRemoveAlert = true
                } label: {
                    HStack {
                        if isRemoving {
                            ProgressView()
                                .tint(.red)
                        } else {
                            Image(systemName: "person.badge.minus")
                        }
                        Text("Remove Friend")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.red)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(isRemoving)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Friend")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Friend?", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeFriend()
            }
        } message: {
            Text("You can always add them back later.")
        }
    }

    private func removeFriend() {
        guard let userID = identityService.currentIdentity?.userIDString else { return }
        isRemoving = true
        Task {
            do {
                try await friendService.removeFriend(friend, currentUserID: userID)
                dismiss()
            } catch {
                print("Failed to remove friend: \(error)")
            }
            isRemoving = false
        }
    }
}

// MARK: - Stat Card

private struct FriendStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.dietCokeCharcoal)

            Text(title)
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(friend: UserProfile(from: UserIdentity(
            displayName: "Test Friend",
            friendCode: "ABC123"
        )))
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
    }
}
