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
    @State private var selectedSection: SocialSection = .leaderboard

    enum SocialSection: String, CaseIterable {
        case leaderboard = "Leaderboard"
        case friends = "Friends"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .leaderboard: return "trophy.fill"
            case .friends: return "person.2.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedSection {
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
        }
    }
}

#Preview {
    SocialTabView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
