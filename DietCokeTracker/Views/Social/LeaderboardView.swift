import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @State private var selectedCategory: LeaderboardCategory = .streak
    @State private var selectedScope: LeaderboardScope = .friends
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    LazyVStack(spacing: 8) {
                        ForEach(entries) { entry in
                            LeaderboardRowView(entry: entry)
                        }
                    }
                    .padding()
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

// MARK: - Category Chip

private struct LeaderboardCategoryChip: View {
    let category: LeaderboardCategory
    let isSelected: Bool
    let action: () -> Void

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
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.2))
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .cornerRadius(20)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 36, height: 36)

                Text("\(entry.rank)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 44, height: 44)

                Text(entry.displayName.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.dietCokeRed)
            }

            // Name and badges
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline)
                        .fontWeight(entry.isCurrentUser ? .bold : .medium)
                        .foregroundColor(.dietCokeCharcoal)

                    if entry.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dietCokeRed)
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
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeRed)

                Text(entry.category.unit)
                    .font(.caption2)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .padding(14)
        .background(entry.isCurrentUser ? Color.dietCokeRed.opacity(0.1) : Color.dietCokeCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isCurrentUser ? Color.dietCokeRed.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0)  // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)  // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        default: return Color.dietCokeDarkSilver
        }
    }
}

// MARK: - Empty Leaderboard

private struct EmptyLeaderboardView: View {
    let scope: LeaderboardScope

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.dietCokeSilver)

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
