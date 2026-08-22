import SwiftUI
import UIKit

struct HomeActivityFeedSection: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var globalFeedService: GlobalFeedService
    @Environment(\.colorScheme) private var colorScheme

    @State private var communityPhotos: [String: UIImage] = [:]

    private var recentActivities: [ActivityItem] {
        Array(activityService.activities.prefix(5))
    }

    /// Friendless users with no activity of their own see recent Global feed
    /// photos instead of a dead "add friends" empty state.
    private var showsCommunity: Bool {
        recentActivities.isEmpty && friendService.friends.isEmpty && !communityItems.isEmpty
    }

    private var communityItems: [ActivityItem] {
        Array(globalFeedService.items.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(showsCommunity ? "FROM THE COMMUNITY" : "ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()

                if showsCommunity {
                    NavigationLink {
                        GlobalFeedView()
                            .navigationTitle("Global Feed")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.dietCokeRed)
                    }
                } else if !activityService.activities.isEmpty {
                    NavigationLink {
                        ActivityFeedView()
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            if activityService.isLoading && recentActivities.isEmpty && !showsCommunity {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if showsCommunity {
                communityStrip
            } else if recentActivities.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(recentActivities) { activity in
                        ActivityItemRow(activity: activity)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
        .task(id: identityService.state) {
            guard identityService.state == .ready,
                  let userID = identityService.currentProfile?.userIDString else { return }
            let friendIDs = friendService.friends.map { $0.userIDString }
            activityService.configure(currentUserID: userID, friendIDs: friendIDs)
            await activityService.fetchActivities()

            // Pull global photos for the community strip when the friends feed
            // has nothing to show.
            if activityService.activities.isEmpty && friendIDs.isEmpty {
                await globalFeedService.refresh()
                for item in communityItems {
                    guard let photoURL = item.payload.photoURL, communityPhotos[photoURL] == nil else { continue }
                    if let image = await globalFeedService.fetchPhoto(recordName: photoURL) {
                        communityPhotos[photoURL] = image
                    }
                }
            }
        }
    }

    private var communityStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(communityItems) { item in
                        communityCell(for: item)
                    }
                }
            }

            Text("Log a drink with a photo to join them")
                .font(.system(size: 12))
                .foregroundColor(.dietCokeDarkSilver)
        }
    }

    @ViewBuilder
    private func communityCell(for item: ActivityItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let photoURL = item.payload.photoURL, let image = communityPhotos[photoURL] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.dietCokeSilver.opacity(0.15))
                    .overlay {
                        ProgressView()
                            .tint(.dietCokeDarkSilver)
                    }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(item.displayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(6)
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeSilver.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 24))
                    .foregroundColor(.dietCokeDarkSilver)
            }

            VStack(spacing: 4) {
                Text("No activity yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.dietCokeCharcoal)
                Text("Add friends to see their activity here")
                    .font(.system(size: 12))
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeActivityFeedSection()
            .padding()
    }
    .withPreviewEnvironment()
}
#endif
