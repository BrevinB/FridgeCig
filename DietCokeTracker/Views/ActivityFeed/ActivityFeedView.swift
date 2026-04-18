import SwiftUI
import UIKit

struct ActivityFeedView: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        themeManager.backgroundColor(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            if activityService.isLoading && activityService.activities.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            ActivityShimmerCard()
                        }
                    }
                    .padding()
                }
                .scrollDisabled(true)
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
        .background(backgroundColor)
        .refreshable {
            await activityService.fetchActivities(force: true)
        }
        .task {
            // Fetch every time the view appears (tab switch recreates the view)
            await loadActivities()
        }
        .onChange(of: identityService.currentProfile?.userIDString) { _, _ in
            Task { await loadActivities() }
        }
        .onChange(of: friendService.friends) { _, _ in
            Task { await loadActivities() }
        }
    }

    private func loadActivities() async {
        guard let userID = identityService.currentProfile?.userIDString else { return }
        let friendIDs = friendService.friends.map { $0.userIDString }
        activityService.configure(currentUserID: userID, friendIDs: friendIDs)
        await activityService.fetchActivities()
    }
}

// MARK: - Empty State

struct EmptyActivityView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeSilver.opacity(0.2), Color.dietCokeSilver.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeSilver, Color.dietCokeDarkSilver],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Activity Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("When your friends earn badges or\nhit milestones, they'll show up here!")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shimmer Card

private struct ActivityShimmerCard: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 120, height: 14)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 10)
                }

                Spacer()
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 60)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: isAnimating ? 300 : -300)
        )
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Activity Item Row

struct ActivityItemRow: View {
    let activity: ActivityItem
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.colorScheme) private var colorScheme

    /// Gold gradient for Pro badge
    private var profileForUser: UserProfile? {
        if activity.userID == identityService.currentProfile?.userIDString {
            return identityService.currentProfile
        }
        return friendService.friends.first { $0.userIDString == activity.userID }
    }

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 0.9, green: 0.7, blue: 0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Activity type icon with Pro ring
                ZStack {
                    // Pro gold ring
                    if activity.isPremium {
                        Circle()
                            .stroke(goldGradient, lineWidth: 2)
                            .frame(width: 48, height: 48)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [activity.type.color.opacity(0.2), activity.type.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    if activity.type.usesCustomIcon {
                        Image(activity.type.icon)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(activity.type.color)
                    } else {
                        Image(systemName: activity.type.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(activity.type.color)
                    }
                }

                // Title and time
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let profile = profileForUser {
                            NavigationLink(value: profile) {
                                Text(activity.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.dietCokeCharcoal)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(activity.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.dietCokeCharcoal)
                        }

                        // Pro badge
                        if activity.isPremium {
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(goldGradient)
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        if activity.isLocalOnly {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.dietCokeDarkSilver)
                        }

                        Text(activity.formattedTime)
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
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
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04),
            radius: 4,
            y: 2
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
                            DrinkIconView(drinkType: drinkType, size: DrinkIconSize.lg)
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
                Button {
                    showingFullScreen = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
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
            HapticManager.cheerSent()

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
