import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @State private var selectedCategory: LeaderboardCategory = .streak
    @State private var selectedScope: LeaderboardScope = .friends
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }

    private var remainingEntries: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scope Picker (Friends vs Global)
            Picker("Scope", selection: $selectedScope) {
                ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LeaderboardCategory.allCases) { category in
                        LeaderboardCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            // Leaderboard Content
            if isLoading {
                Spacer()
                ProgressView("Loading leaderboard...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                ErrorMessageView(message: error) {
                    Task { await loadLeaderboard() }
                }
                Spacer()
            } else if entries.isEmpty {
                Spacer()
                EmptyLeaderboardView(scope: selectedScope)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero Podium Card (only show if we have 3+ entries)
                        if topThree.count >= 3 {
                            LeaderboardPodiumCard(
                                topThree: topThree,
                                category: selectedCategory
                            )
                            .padding(.horizontal)

                            // Show remaining entries (4th place and beyond)
                            if !remainingEntries.isEmpty {
                                LazyVStack(spacing: 8) {
                                    ForEach(remainingEntries) { entry in
                                        LeaderboardRowView(entry: entry)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // Less than 3 entries - show all as regular rows
                            LazyVStack(spacing: 8) {
                                ForEach(entries) { entry in
                                    LeaderboardRowView(entry: entry)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            Task { await loadLeaderboard() }
        }
        .onChange(of: selectedScope) { _, _ in
            Task { await loadLeaderboard() }
        }
        .task {
            await loadLeaderboard()
        }
        .refreshable {
            await loadLeaderboard()
        }
    }

    private func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentUserID = identityService.currentIdentity?.userIDString

            #if DEBUG
            // Use fake data if available
            if friendService.isUsingFakeData && selectedScope == .friends {
                entries = friendService.getFakeLeaderboard(
                    category: selectedCategory,
                    currentUserID: currentUserID,
                    currentUserProfile: identityService.currentProfile
                )
                isLoading = false
                return
            }
            #endif

            entries = try await friendService.fetchLeaderboard(
                category: selectedCategory,
                scope: selectedScope,
                currentUserID: currentUserID
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Leaderboard Podium Card

struct LeaderboardPodiumCard: View {
    let topThree: [LeaderboardEntry]
    let category: LeaderboardCategory
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background with metallic gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)

            // Ambient bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 16) {
                // Title
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.84, blue: 0), Color(red: 0.9, green: 0.7, blue: 0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Top Performers")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)
                }

                // Podium
                HStack(alignment: .bottom, spacing: 8) {
                    // 2nd place (left)
                    if topThree.count > 1 {
                        PodiumEntry(entry: topThree[1], rank: 2, category: category)
                    }

                    // 1st place (center, taller)
                    if topThree.count > 0 {
                        PodiumEntry(entry: topThree[0], rank: 1, category: category)
                    }

                    // 3rd place (right)
                    if topThree.count > 2 {
                        PodiumEntry(entry: topThree[2], rank: 3, category: category)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 220)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 10,
            y: 4
        )
    }
}

// MARK: - Podium Entry

private struct PodiumEntry: View {
    let entry: LeaderboardEntry
    let rank: Int
    let category: LeaderboardCategory

    private var podiumHeight: CGFloat {
        switch rank {
        case 1: return 80
        case 2: return 60
        case 3: return 45
        default: return 40
        }
    }

    private var medalColor: [Color] {
        switch rank {
        case 1: return [Color(red: 1.0, green: 0.84, blue: 0), Color(red: 0.9, green: 0.7, blue: 0)] // Gold
        case 2: return [Color(red: 0.82, green: 0.82, blue: 0.85), Color(red: 0.68, green: 0.68, blue: 0.72)] // Silver
        case 3: return [Color(red: 0.85, green: 0.55, blue: 0.25), Color(red: 0.7, green: 0.45, blue: 0.2)] // Bronze
        default: return [.gray, .gray]
        }
    }

    private var medalIcon: String {
        rank == 1 ? "crown.fill" : "medal.fill"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar with medal
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: medalColor,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: rank == 1 ? 48 : 40, height: rank == 1 ? 48 : 40)

                Text(entry.displayName.prefix(1).uppercased())
                    .font(.system(size: rank == 1 ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)

                // Medal badge
                Image(systemName: medalIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: medalColor,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .offset(x: rank == 1 ? 18 : 14, y: rank == 1 ? -18 : -14)
            }

            // Name
            Text(entry.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)
                .lineLimit(1)

            // Value
            Text(entry.formattedValue)
                .font(.system(size: rank == 1 ? 18 : 14, weight: .bold, design: .rounded))
                .foregroundColor(.dietCokeRed)

            // Podium block
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: medalColor,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: podiumHeight)
                .overlay(
                    Text("\(rank)")
                        .font(.system(size: rank == 1 ? 24 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Chip

private struct LeaderboardCategoryChip: View {
    let category: LeaderboardCategory
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(colorScheme == .dark ? Color(white: 0.15) : .white)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.dietCokeRed.opacity(0.3) : Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    var isPremiumUser: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    /// Gold gradient for Pro badge
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
        HStack(spacing: 14) {
            // Rank
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rankGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                if entry.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Avatar with Pro ring
            ZStack {
                // Pro gold ring
                if entry.isPremium {
                    Circle()
                        .stroke(goldGradient, lineWidth: 2)
                        .frame(width: 48, height: 48)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(entry.displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.dietCokeRed)
            }

            // Name and badges
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline)
                        .fontWeight(entry.isCurrentUser ? .bold : .medium)
                        .foregroundColor(.dietCokeCharcoal)

                    // Pro badge
                    if entry.isPremium {
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

                    if entry.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }

                if entry.isFriend && !entry.isCurrentUser {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("Friend")
                            .font(.caption2)
                    }
                    .foregroundColor(.dietCokeDarkSilver)
                }
            }

            Spacer()

            // Value
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.dietCokeRed)

                Text(entry.category.unit)
                    .font(.caption2)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(entry.isCurrentUser
                      ? Color.dietCokeRed.opacity(colorScheme == .dark ? 0.15 : 0.08)
                      : (colorScheme == .dark ? Color(white: 0.12) : Color.white))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(entry.isCurrentUser ? Color.dietCokeRed.opacity(0.3) : Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04),
            radius: 4,
            y: 2
        )
    }

    private var rankGradient: [Color] {
        switch entry.rank {
        case 1: return [Color(red: 1.0, green: 0.84, blue: 0), Color(red: 0.9, green: 0.7, blue: 0)]  // Gold
        case 2: return [Color(red: 0.82, green: 0.82, blue: 0.85), Color(red: 0.68, green: 0.68, blue: 0.72)]  // Silver
        case 3: return [Color(red: 0.85, green: 0.55, blue: 0.25), Color(red: 0.7, green: 0.45, blue: 0.2)]  // Bronze
        default: return [Color.dietCokeDarkSilver, Color.dietCokeSilver]
        }
    }

    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
}

// MARK: - Empty Leaderboard

private struct EmptyLeaderboardView: View {
    let scope: LeaderboardScope

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeSilver.opacity(0.2), Color.dietCokeSilver.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "trophy")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeSilver, Color.dietCokeDarkSilver],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(scope == .friends ? "No Friends Yet" : "No One Here Yet")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(scope == .friends
                     ? "Add friends to see how you compare!"
                     : "Be the first to join the global leaderboard!")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Error Message

private struct ErrorMessageView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Couldn't Load Leaderboard")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again", action: onRetry)
                .buttonStyle(.dietCokePrimary)
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
