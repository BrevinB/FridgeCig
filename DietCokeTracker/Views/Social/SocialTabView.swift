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
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Error View

private struct ErrorView: View {
    @EnvironmentObject var identityService: IdentityService

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            if let error = identityService.error {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Main Social View

struct SocialMainView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedSection: SocialSection = .leaderboard

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar with badge support
                HStack(spacing: 0) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        SocialTabButton(
                            section: section,
                            isSelected: selectedSection == section,
                            badgeCount: section == .friends ? friendService.pendingRequests.count : 0
                        ) {
                            selectedSection = section
                        }
                    }
                }
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
            .background(Color(.systemGroupedBackground))
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
                    Image(systemName: section.icon)
                        .font(.system(size: 18))

                    // Badge
                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .offset(x: 8, y: -6)
                    }
                }

                Text(section.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .dietCokeRed : .dietCokeDarkSilver)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.dietCokeRed.opacity(0.1) : Color.clear)
            )
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
