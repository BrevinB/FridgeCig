import SwiftUI

struct HomeActivityFeedSection: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.colorScheme) private var colorScheme

    private var recentActivities: [ActivityItem] {
        Array(activityService.activities.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()

                if !activityService.activities.isEmpty {
                    NavigationLink {
                        ActivityFeedView()
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            if activityService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
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
        }
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
