import SwiftUI
import os

struct FriendsListView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingAddFriend = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pending Requests Section
                if !friendService.pendingRequests.isEmpty {
                    PendingRequestsSection()
                }

                // Friends Section
                FriendsSection(showingAddFriend: $showingAddFriend)
            }
            .padding()
        }
        .refreshable {
            await loadFriends()
        }
        .task {
            await loadFriends()
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                AppLogger.friends.debug("App became active, refreshing friends")
                Task {
                    await loadFriends()
                }
            }
        }
    }

    private func loadFriends() async {
        guard let userID = identityService.currentIdentity?.userIDString else { return }
        await friendService.loadFriends(forUserID: userID)
    }
}

// MARK: - Pending Requests Section

private struct PendingRequestsSection: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.clock")
                    .foregroundColor(.orange)
                Text("Friend Requests")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Text("\(friendService.pendingRequests.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            ForEach(friendService.pendingRequests) { request in
                PendingRequestRow(request: request)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Pending Request Row

private struct PendingRequestRow: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    let request: FriendConnection
    @State private var requesterProfile: UserProfile?
    @State private var isLoading = true
    @State private var isAccepting = false
    @State private var isDeclining = false
    @State private var errorMessage: String?

    private var displayName: String {
        requesterProfile?.displayName ?? "Unknown User"
    }

    private var displayInitial: String {
        if let profile = requesterProfile {
            return String(profile.displayName.prefix(1)).uppercased()
        }
        return "?"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 44, height: 44)

                if isLoading {
                    ProgressView()
                } else {
                    Text(displayInitial)
                        .font(.headline)
                        .foregroundColor(.dietCokeRed)
                }
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                if isLoading {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                } else {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)
                }

                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Spacer()

            // Actions - always enabled once loading is done
            HStack(spacing: 8) {
                Button {
                    decline()
                } label: {
                    if isDeclining {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
                .disabled(isLoading || isAccepting || isDeclining)

                Button {
                    accept()
                } label: {
                    if isAccepting {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .disabled(isLoading || isAccepting || isDeclining)
            }
        }
        .padding(12)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
        .overlay {
            if let error = errorMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button {
                            errorMessage = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(4)
            }
        }
        .task {
            await loadRequesterProfile()
        }
    }

    private func loadRequesterProfile() async {
        isLoading = true
        do {
            requesterProfile = try await friendService.lookupUserByID(request.requesterID)
        } catch {
            AppLogger.friends.error("Failed to load requester profile: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func accept() {
        guard let userID = identityService.currentIdentity?.userIDString else {
            AppLogger.friends.error("Accept failed: no userID")
            errorMessage = "Unable to accept request"
            return
        }
        AppLogger.friends.debug("Accepting request: \(request.id)")
        isAccepting = true
        errorMessage = nil
        HapticManager.friendAction()
        Task {
            do {
                try await friendService.acceptRequest(request, currentUserID: userID)
                AppLogger.friends.debug("Accept succeeded")
            } catch {
                AppLogger.friends.error("Accept failed: \(error.localizedDescription)")
                errorMessage = "Failed to accept"
                HapticManager.error()
            }
            isAccepting = false
        }
    }

    private func decline() {
        AppLogger.friends.debug("Declining request: \(request.id)")
        isDeclining = true
        errorMessage = nil
        HapticManager.lightImpact()
        Task {
            do {
                try await friendService.declineRequest(request)
                AppLogger.friends.debug("Decline succeeded")
            } catch {
                AppLogger.friends.error("Decline failed: \(error.localizedDescription)")
                errorMessage = "Failed to decline"
                HapticManager.error()
            }
            isDeclining = false
        }
    }
}

// MARK: - Friends Section

private struct FriendsSection: View {
    @EnvironmentObject var friendService: FriendConnectionService
    @Binding var showingAddFriend: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Friends")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Button {
                    showingAddFriend = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeRed)
                }
            }

            if friendService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if let error = friendService.error {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Couldn't load friends")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if friendService.friends.isEmpty {
                EmptyFriendsView(showingAddFriend: $showingAddFriend)
            } else {
                ForEach(friendService.friends) { friend in
                    FriendRow(friend: friend)
                }
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Empty Friends View

private struct EmptyFriendsView: View {
    @Binding var showingAddFriend: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.dietCokeSilver)

            Text("No friends yet")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)

            Button {
                showingAddFriend = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Your First Friend")
                }
            }
            .buttonStyle(.dietCokePrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Friend Row

private struct FriendRow: View {
    let friend: UserProfile

    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend)) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.dietCokeRed.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.dietCokeRed)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)

                    // Stats preview
                    HStack(spacing: 12) {
                        StatBadge(icon: "flame.fill", value: "\(friend.currentStreak)", color: .orange)
                        StatBadge(icon: "cup.and.saucer.fill", value: "\(friend.allTimeDrinks)", color: .dietCokeRed)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.dietCokeSilver)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
            .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
    }
}
