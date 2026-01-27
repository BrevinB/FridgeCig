import SwiftUI
import UIKit

struct ActivityFeedView: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @State private var showingPreferences = false

    var body: some View {
        VStack(spacing: 0) {
            if activityService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activityService.activities.isEmpty {
                EmptyActivityView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activityService.activities) { activity in
                            ActivityItemRow(activity: activity)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Activity")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPreferences = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .refreshable {
            await activityService.fetchActivities()
        }
        .sheet(isPresented: $showingPreferences) {
            SharingPreferencesView()
        }
        .task {
            // Configure with current user and friends
            if let userID = identityService.currentProfile?.userIDString {
                let friendIDs = friendService.friends.map { $0.userIDString }
                activityService.configure(currentUserID: userID, friendIDs: friendIDs)
                await activityService.fetchActivities()
            }
        }
    }
}

// MARK: - Empty State

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 50))
                .foregroundColor(.dietCokeSilver)

            Text("No Activity Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            Text("When your friends earn badges or hit milestones, they'll show up here!")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Activity Item Row

struct ActivityItemRow: View {
    let activity: ActivityItem
    @EnvironmentObject var activityService: ActivityFeedService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Activity type icon
                ZStack {
                    Circle()
                        .fill(activity.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: activity.type.icon)
                        .font(.body)
                        .foregroundColor(activity.type.color)
                }

                // Title and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)

                    Text(activity.formattedTime)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()
            }

            // Content based on type
            ActivityContent(activity: activity)

            // Actions
            HStack {
                CheersButton(activity: activity)

                Spacer()

                // Badge rarity if applicable
                if let rarity = activity.payload.badgeRarity {
                    Text(rarity.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(rarity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(rarity.color.opacity(0.2))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Activity Content

struct ActivityContent: View {
    let activity: ActivityItem

    var body: some View {
        Group {
            switch activity.type {
            case .badgeUnlock:
                if let title = activity.payload.badgeTitle,
                   let icon = activity.payload.badgeIcon {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dietCokeCharcoal)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }

            case .streakMilestone:
                if let days = activity.payload.streakDays,
                   let message = activity.payload.streakMessage {
                    HStack(spacing: 12) {
                        Text("\(days)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day Streak")
                                .font(.caption)
                                .foregroundColor(.dietCokeDarkSilver)
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.dietCokeCharcoal)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }

            case .drinkLog:
                if let drinkType = activity.payload.drinkType {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: drinkType.icon)
                                .font(.title2)
                                .foregroundColor(.dietCokeRed)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(drinkType.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.dietCokeCharcoal)

                                if let note = activity.payload.drinkNote {
                                    Text("\"\(note)\"")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeDarkSilver)
                                        .italic()
                                }
                            }

                            Spacer()

                            if activity.payload.hasPhoto == true && activity.payload.photoURL == nil {
                                // Has photo but not shared
                                Image(systemName: "photo.fill")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                        }

                        // Display shared photo if available
                        if let photoURL = activity.payload.photoURL {
                            ActivityPhotoView(photoRecordName: photoURL)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dietCokeRed.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - Activity Photo View

struct ActivityPhotoView: View {
    let photoRecordName: String
    @EnvironmentObject var activityService: ActivityFeedService
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showingFullScreen = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
                    .onTapGesture {
                        showingFullScreen = true
                    }
            } else if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                    )
            } else {
                // Failed to load
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 100)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                            Text("Photo unavailable")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .task {
            await loadPhoto()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let image = image {
                ActivityFullScreenPhotoView(image: image)
            }
        }
    }

    private func loadPhoto() async {
        isLoading = true
        image = await activityService.fetchPhoto(recordName: photoRecordName)
        isLoading = false
    }
}

// MARK: - Full Screen Photo View

struct ActivityFullScreenPhotoView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
}

// MARK: - Cheers Button

struct CheersButton: View {
    let activity: ActivityItem
    @EnvironmentObject var activityService: ActivityFeedService
    @State private var isAnimating = false

    var hasCheered: Bool {
        activityService.hasUserCheered(activity)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isAnimating = true
            }

            Task {
                await activityService.toggleCheers(for: activity)
                isAnimating = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: hasCheered ? "hands.clap.fill" : "hands.clap")
                    .font(.body)
                    .symbolEffect(.bounce, value: isAnimating)

                if activity.cheersCount > 0 {
                    Text("\(activity.cheersCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(hasCheered ? .orange : .dietCokeDarkSilver)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(hasCheered ? Color.orange.opacity(0.15) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ActivityFeedView()
            .environmentObject(ActivityFeedService(cloudKitManager: CloudKitManager()))
            .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
            .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
    }
}
