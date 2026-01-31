import SwiftUI

struct SocialTabView: View {
    @EnvironmentObject var identityService: IdentityService

    var body: some View {
        Group {
            switch identityService.state {
            case .loading:
                LoadingView()
            case .noIdentity:
                SetupProfileView()
            case .ready:
                SocialMainView()
            case .error:
                ErrorView()
            }
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 80, height: 80)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.dietCokeRed)
            }

            Text("Loading...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Error View

private struct ErrorView: View {
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                if let error = identityService.error {
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Button("Try Again") {
                Task {
                    await identityService.initialize()
                }
            }
            .buttonStyle(.dietCokePrimary)
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Main Social View

struct SocialMainView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: SocialSection = .leaderboard
    @State private var showingAddFriendFromDeepLink = false

    enum SocialSection: String, CaseIterable {
        case activity = "Activity"
        case leaderboard = "Leaderboard"
        case friends = "Friends"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .activity: return "bell.fill"
            case .leaderboard: return "trophy.fill"
            case .friends: return "person.2.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar with badge support
                HStack(spacing: 4) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        SocialTabButton(
                            section: section,
                            isSelected: selectedSection == section,
                            badgeCount: section == .friends ? friendService.pendingRequests.count : 0
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSection = section
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                switch selectedSection {
                case .activity:
                    ActivityFeedView()
                case .leaderboard:
                    LeaderboardView()
                case .friends:
                    FriendsListView()
                case .profile:
                    ProfileView()
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Social")
            .task {
                // Load friends to get pending request count
                if let userID = identityService.currentIdentity?.userIDString {
                    await friendService.loadFriends(forUserID: userID)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    print("[SocialMainView] App became active, refreshing friend data for badge...")
                    Task {
                        if let userID = identityService.currentIdentity?.userIDString {
                            await friendService.loadFriends(forUserID: userID)
                        }
                    }
                }
            }
            // Handle deep link friend code
            .onChange(of: deepLinkHandler.shouldNavigateToAddFriend) { _, shouldNavigate in
                if shouldNavigate {
                    selectedSection = .friends
                    showingAddFriendFromDeepLink = true
                }
            }
            .sheet(isPresented: $showingAddFriendFromDeepLink, onDismiss: {
                deepLinkHandler.clearPendingFriendCode()
            }) {
                NavigationStack {
                    ShareCodeView(initialCode: deepLinkHandler.pendingFriendCode)
                        .navigationTitle("Add Friend")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showingAddFriendFromDeepLink = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Social Tab Button

private struct SocialTabButton: View {
    let section: SocialMainView.SocialSection
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                        }

                        Image(systemName: section.icon)
                            .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    }

                    // Badge
                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(
                                Circle()
                                    .fill(Color.dietCokeRed)
                            )
                            .offset(x: 10, y: -4)
                    }
                }
                .frame(height: 36)

                Text(section.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .dietCokeRed : .dietCokeDarkSilver)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let ckManager = CloudKitManager()
    return SocialTabView()
        .environmentObject(IdentityService(cloudKitManager: ckManager))
        .environmentObject(FriendConnectionService(cloudKitManager: ckManager))
        .environmentObject(ActivityFeedService(cloudKitManager: ckManager))
}
