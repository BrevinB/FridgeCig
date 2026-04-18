import SwiftUI
import os

struct FriendDetailView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.dismiss) private var dismiss

    let friend: UserProfile
    @State private var showingRemoveAlert = false
    @State private var isRemoving = false
    @State private var isSendingRequest = false
    @State private var requestSent = false

    private enum Relationship {
        case currentUser
        case friend
        case requestSent
        case stranger
    }

    private var relationship: Relationship {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return .stranger }
        if friend.userIDString == currentUserID { return .currentUser }
        if friendService.friends.contains(where: { $0.userIDString == friend.userIDString }) { return .friend }
        if requestSent { return .requestSent }
        if friendService.sentRequests.contains(where: { $0.targetID == friend.userIDString }) { return .requestSent }
        return .stranger
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    AvatarView(
                        displayName: friend.displayName,
                        profilePhotoID: friend.profilePhotoID,
                        profileEmoji: friend.profileEmoji,
                        size: 100,
                        showGradientRing: true
                    )

                    Text(friend.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dietCokeCharcoal)

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

                // Badges Section
                if !friend.earnedBadgeIDs.isEmpty {
                    badgesSection
                }

                // Action Button
                actionButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(relationship == .friend ? "Friend" : "Profile")
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

    @ViewBuilder
    private var actionButton: some View {
        switch relationship {
        case .currentUser:
            EmptyView()

        case .friend:
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

        case .requestSent:
            HStack {
                Image(systemName: "clock")
                Text("Request Sent")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.dietCokeDarkSilver)
            .background(Color(.systemGray5))
            .cornerRadius(12)

        case .stranger:
            Button {
                sendRequest()
            } label: {
                HStack {
                    if isSendingRequest {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text("Add Friend")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isSendingRequest)
        }
    }

    private var earnedBadges: [Badge] {
        friend.earnedBadgeIDs.compactMap { id in
            var badge = BadgeDefinitions.all.first { $0.id == id }
            badge?.unlockedAt = Date()
            return badge
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Badges")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Text("\(friend.earnedBadgeIDs.count)/\(BadgeDefinitions.all.count)")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(earnedBadges) { badge in
                    BadgeView(badge: badge, size: .small, showDetails: true)
                }
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }

    private func removeFriend() {
        guard let userID = identityService.currentIdentity?.userIDString else { return }
        isRemoving = true
        Task {
            do {
                try await friendService.removeFriend(friend, currentUserID: userID)
                dismiss()
            } catch {
                AppLogger.friends.error("Failed to remove friend: \(error.localizedDescription)")
            }
            isRemoving = false
        }
    }

    private func sendRequest() {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return }
        isSendingRequest = true
        Task {
            do {
                try await friendService.sendFriendRequest(from: currentUserID, to: friend)
                requestSent = true
                HapticManager.success()
            } catch {
                AppLogger.friends.error("Failed to send friend request: \(error.localizedDescription)")
            }
            isSendingRequest = false
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
