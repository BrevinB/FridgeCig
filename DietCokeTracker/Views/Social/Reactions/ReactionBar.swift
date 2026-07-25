import SwiftUI

/// The row of emoji reactions under a feed post.
///
/// Existing reactions render as tappable chips; the trailing button opens the
/// full picker. Tapping the emoji you already left removes it, tapping a
/// different one swaps it — one reaction per person, same as iMessage.
struct ReactionBar: View {
    let activity: ActivityItem
    /// Compact mode drops the chip labels for tight layouts.
    var compact: Bool = false

    @EnvironmentObject private var activityService: ActivityFeedService

    @State private var showingPicker = false
    @State private var showingReactors = false
    @State private var animatingEmoji: ReactionEmoji?

    private var groups: [ReactionGroup] {
        activityService.reactionGroups(for: activity)
    }

    private var myReaction: ReactionEmoji? {
        activityService.myReaction(on: activity)
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(groups) { group in
                ReactionChip(
                    group: group,
                    isMine: myReaction == group.emoji,
                    isAnimating: animatingEmoji == group.emoji,
                    compact: compact
                ) {
                    react(with: group.emoji)
                }
                .accessibilityLabel("\(group.emoji.label), \(group.count)")
                .accessibilityHint(myReaction == group.emoji ? "Double tap to remove your reaction" : "Double tap to react")
            }

            AddReactionButton(hasReacted: myReaction != nil) {
                HapticManager.lightImpact()
                showingPicker = true
            }
            .popover(isPresented: $showingPicker) {
                ReactionPicker(
                    selected: myReaction,
                    onSelect: { emoji in
                        showingPicker = false
                        react(with: emoji)
                    }
                )
                .presentationCompactAdaptation(.popover)
            }

            if !groups.isEmpty {
                Button {
                    showingReactors = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.dietCokeDarkSilver)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See who reacted")
            }
        }
        .sheet(isPresented: $showingReactors) {
            ReactorsSheet(groups: groups)
        }
    }

    private func react(with emoji: ReactionEmoji) {
        HapticManager.cheerSent()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animatingEmoji = emoji
        }

        Task {
            await activityService.toggleReaction(emoji, on: activity)
            try? await Task.sleep(for: .milliseconds(350))
            animatingEmoji = nil
        }
    }
}

// MARK: - Reaction Chip

private struct ReactionChip: View {
    // Declared ahead of the stored parameters so the trailing-closure call site
    // stays valid.
    @Environment(\.colorScheme) private var colorScheme

    let group: ReactionGroup
    let isMine: Bool
    let isAnimating: Bool
    let compact: Bool
    let action: () -> Void

    private var background: Color {
        if isMine { return Color.dietCokeRed.opacity(colorScheme == .dark ? 0.25 : 0.12) }
        return colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray6)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(group.emoji.rawValue)
                    .font(.system(size: compact ? 13 : 15))
                    .scaleEffect(isAnimating ? 1.35 : 1.0)

                if group.count > 0 {
                    Text("\(group.count)")
                        .font(.system(size: compact ? 11 : 12, weight: .semibold))
                        .foregroundColor(isMine ? .dietCokeRed : .dietCokeDarkSilver)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(Capsule().fill(background))
            .overlay(
                Capsule()
                    .stroke(isMine ? Color.dietCokeRed.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Reaction Button

private struct AddReactionButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let hasReacted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: hasReacted ? "face.smiling" : "face.smiling.inverse")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.dietCokeDarkSilver)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a reaction")
    }
}

// MARK: - Reaction Picker

struct ReactionPicker: View {
    let selected: ReactionEmoji?
    let onSelect: (ReactionEmoji) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ReactionEmoji.allCases) { emoji in
                Button {
                    onSelect(emoji)
                } label: {
                    Text(emoji.rawValue)
                        .font(.system(size: 26))
                        .padding(7)
                        .background(
                            Circle()
                                .fill(selected == emoji
                                      ? Color.dietCokeRed.opacity(0.15)
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(emoji.label)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Reactors Sheet

/// Who reacted, and with what. Names resolve from the friends list; anyone
/// outside it is looked up once and cached for the life of the sheet.
struct ReactorsSheet: View {
    let groups: [ReactionGroup]

    @EnvironmentObject private var friendService: FriendConnectionService
    @EnvironmentObject private var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss

    @State private var resolvedProfiles: [String: UserProfile] = [:]
    @State private var selectedEmoji: ReactionEmoji?

    private var totalCount: Int {
        groups.reduce(0) { $0 + $1.count }
    }

    private var visibleGroups: [ReactionGroup] {
        guard let selectedEmoji else { return groups }
        return groups.filter { $0.emoji == selectedEmoji }
    }

    /// One row per person. A user holds at most one reaction, so the user ID is
    /// a stable identity across the whole list.
    private struct Reactor: Identifiable {
        let userID: String
        let emoji: ReactionEmoji

        var id: String { userID }
    }

    private var reactorRows: [Reactor] {
        visibleGroups.flatMap { group in
            group.userIDs.map { Reactor(userID: $0, emoji: group.emoji) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if reactorRows.isEmpty {
                    // Legacy posts recorded a count without the user list.
                    ContentUnavailableView(
                        "\(totalCount) Reaction\(totalCount == 1 ? "" : "s")",
                        systemImage: "hands.clap",
                        description: Text("This post was cheered before we started tracking who reacted.")
                    )
                } else {
                    List {
                        ForEach(reactorRows) { row in
                            ReactorRow(
                                emoji: row.emoji,
                                profile: profile(for: row.userID),
                                isCurrentUser: row.userID == identityService.currentProfile?.userIDString
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .safeAreaInset(edge: .top) {
                if groups.count > 1 {
                    filterBar
                }
            }
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await resolveMissingProfiles()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All \(totalCount)", isSelected: selectedEmoji == nil) {
                    selectedEmoji = nil
                }

                ForEach(groups) { group in
                    FilterChip(
                        title: "\(group.emoji.rawValue) \(group.count)",
                        isSelected: selectedEmoji == group.emoji
                    ) {
                        selectedEmoji = group.emoji
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func profile(for userID: String) -> UserProfile? {
        if userID == identityService.currentProfile?.userIDString {
            return identityService.currentProfile
        }
        if let friend = friendService.friends.first(where: { $0.userIDString == userID }) {
            return friend
        }
        return resolvedProfiles[userID]
    }

    /// Anyone who isn't a friend needs a profile lookup for their name. Run
    /// concurrently and capped — a viral post shouldn't fire off a hundred
    /// serial queries to label a list the user is scrolling past.
    private func resolveMissingProfiles() async {
        let unknown = Set(reactorRows.map { $0.userID })
            .filter { profile(for: $0) == nil }
            .prefix(Self.profileLookupLimit)
        guard !unknown.isEmpty else { return }

        let service = friendService
        let resolved = await withTaskGroup(of: (String, UserProfile?).self) { group in
            for userID in unknown {
                group.addTask { @MainActor in
                    (userID, try? await service.lookupUserByID(userID))
                }
            }

            var results: [String: UserProfile] = [:]
            for await (userID, profile) in group {
                if let profile { results[userID] = profile }
            }
            return results
        }

        resolvedProfiles.merge(resolved) { _, new in new }
    }

    private static let profileLookupLimit = 30
}

// MARK: - Reactor Row

private struct ReactorRow: View {
    let emoji: ReactionEmoji
    let profile: UserProfile?
    let isCurrentUser: Bool

    private var displayName: String {
        if isCurrentUser { return "You" }
        return profile?.displayName ?? "FridgeCig user"
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                displayName: displayName,
                profilePhotoID: profile?.profilePhotoID,
                profileEmoji: profile?.profileEmoji,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                if let username = profile?.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            Spacer()

            Text(emoji.rawValue)
                .font(.system(size: 22))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? Color.dietCokeRed
                              : (colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray6)))
                )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 20) {
        ReactionBar(activity: PreviewSamples.sampleActivity())
        ReactionBar(activity: PreviewSamples.sampleActivity(), compact: true)
    }
    .padding()
    .withPreviewEnvironment()
}
#endif
