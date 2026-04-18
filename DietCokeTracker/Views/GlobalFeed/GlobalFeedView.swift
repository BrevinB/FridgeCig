import SwiftUI

struct GlobalFeedView: View {
    @EnvironmentObject var globalFeedService: GlobalFeedService
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedItem: ActivityItem?
    @State private var photoCache: [String: UIImage] = [:]
    @State private var showingPreferences = false
    @State private var hasAppeared = false

    private var isGlobalSharingEnabled: Bool {
        activityService.sharingPreferences.sharePhotosGlobally
    }

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isGlobalSharingEnabled {
                optInBanner
            }

            if globalFeedService.items.isEmpty && !globalFeedService.isLoading {
                emptyState
            } else if globalFeedService.items.isEmpty && globalFeedService.isLoading {
                loadingGrid
            } else {
                feedGrid
            }
        }
        .background(backgroundColor)
        .task {
            globalFeedService.observeCheersUpdates(from: activityService)
            if globalFeedService.items.isEmpty {
                if let userID = identityService.currentIdentity?.userIDString {
                    let blockedIDs = (try? await friendService.fetchBlockedUserIDs(forUserID: userID)) ?? []
                    globalFeedService.configure(blockedUserIDs: blockedIDs)
                }
                await globalFeedService.refresh()
            }
        }
        .sheet(item: $selectedItem) { item in
            // Pass the live item from the service so cheers state stays current
            let liveItem = globalFeedService.items.first(where: { $0.id == item.id }) ?? item
            GlobalFeedDetailView(
                item: liveItem,
                photo: photoCache[item.payload.photoURL ?? ""]
            )
        }
        .onChange(of: showingPreferences) { _, _ in }
        .sheet(isPresented: $showingPreferences) {
            SharingPreferencesView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Opt-In Banner

    private var optInBanner: some View {
        Button {
            showingPreferences = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "globe")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.dietCokeRed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Join the Global feed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)
                    Text("Share your photos with the community")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.dietCokeRed, .dietCokeRed.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Photos Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("When users share photos globally,\nthey'll appear here.")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading Skeleton Grid

    private var loadingGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<8, id: \.self) { _ in
                    ShimmerCell()
                }
            }
            .padding(.horizontal, 3)
            .padding(.top, 3)
        }
        .scrollDisabled(true)
    }

    // MARK: - Feed Grid

    private var feedGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(Array(globalFeedService.items.enumerated()), id: \.element.id) { index, item in
                    GlobalFeedCard(
                        item: item,
                        photo: photoCache[item.payload.photoURL ?? ""]
                    )
                    .onTapGesture {
                        selectedItem = item
                    }
                    .onAppear {
                        if let photoURL = item.payload.photoURL, photoCache[photoURL] == nil {
                            Task {
                                if let image = await globalFeedService.fetchPhoto(recordName: photoURL) {
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        photoCache[photoURL] = image
                                    }
                                }
                            }
                        }

                        if item.id == globalFeedService.items.last?.id {
                            Task {
                                await globalFeedService.loadMore()
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 3)
            .padding(.top, 3)

            if globalFeedService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.dietCokeRed)
                    Text("Loading more...")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
                .padding(.vertical, 16)
            }
        }
        .refreshable {
            await globalFeedService.refresh(force: true)
        }
    }
}

// MARK: - Shimmer Loading Cell

private struct ShimmerCell: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Feed Card

private struct GlobalFeedCard: View {
    let item: ActivityItem
    let photo: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo or loading state
            if let photo = photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            } else {
                let placeholderFill = colorScheme == .dark ? Color(white: 0.15) : Color.gray.opacity(0.12)
                Rectangle()
                    .fill(placeholderFill)
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay {
                        ProgressView()
                            .tint(.dietCokeDarkSilver)
                    }
            }

            // Bottom gradient overlay with info
            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    // Info pills row
                    HStack(spacing: 4) {
                        if let drinkType = item.payload.drinkType {
                            Text(drinkType.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.25))
                                )
                        }

                        if item.payload.drinkSpecialEdition != nil {
                            Image(systemName: "sparkle")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }

                        if let rating = item.payload.drinkRating {
                            HStack(spacing: 2) {
                                Image(systemName: rating.icon)
                                    .font(.system(size: 8))
                                    .foregroundColor(rating.color)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    }

                    HStack(alignment: .center) {
                        Text(item.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer()

                        if item.cheersCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "hands.clap.fill")
                                    .font(.system(size: 10))
                                Text("\(item.cheersCount)")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .padding(.top, 24)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Time badge in top-right
            VStack {
                HStack {
                    Spacer()
                    Text(item.formattedTime)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.4))
                        )
                        .padding(6)
                }
                Spacer()
            }
        }
        .contentShape(Rectangle())
    }
}
