import Foundation

// MARK: - Reaction Emoji

/// The reactions a user can leave on a feed post. Ordered the way they appear
/// in the picker.
enum ReactionEmoji: String, CaseIterable, Codable, Identifiable, Hashable {
    case clap = "👏"
    case fire = "🔥"
    case ice = "🧊"
    case laugh = "😂"
    case eyes = "👀"
    case heart = "❤️"

    var id: String { rawValue }

    /// Posts created before per-emoji reactions only stored a flat list of
    /// user IDs. Those are surfaced as claps.
    static let legacyDefault: ReactionEmoji = .clap

    var label: String {
        switch self {
        case .clap: return "Cheers"
        case .fire: return "Fire"
        case .ice: return "Ice Cold"
        case .laugh: return "Funny"
        case .eyes: return "Eyes"
        case .heart: return "Love"
        }
    }

    /// Past-tense phrasing used in notification copy: "Alex cheered your post".
    var verb: String {
        switch self {
        case .clap: return "cheered"
        case .fire: return "fired up"
        case .ice: return "iced"
        case .laugh: return "laughed at"
        case .eyes: return "is eyeing"
        case .heart: return "loved"
        }
    }
}

// MARK: - Reaction

/// One user's reaction to one activity. A user holds at most one reaction per
/// post — reacting again replaces the previous emoji.
struct Reaction: Codable, Equatable, Identifiable {
    let userID: String
    let emoji: ReactionEmoji

    var id: String { userID }
}

extension Reaction {
    private static let separator: Character = "|"

    /// Serialized as `userID|emoji` so an entire reaction set fits in a single
    /// CloudKit string-list field, avoiding a per-reaction record.
    var token: String { "\(userID)\(Self.separator)\(emoji.rawValue)" }

    init?(token: String) {
        let parts = token.split(separator: Self.separator, maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              let emoji = ReactionEmoji(rawValue: String(parts[1])) else {
            return nil
        }
        self.userID = String(parts[0])
        self.emoji = emoji
    }
}

// MARK: - Reaction Group

/// One emoji plus everyone who left it — the unit the reaction bar renders.
struct ReactionGroup: Identifiable, Equatable {
    let emoji: ReactionEmoji
    let userIDs: [String]
    let count: Int

    var id: String { emoji.rawValue }

    init(emoji: ReactionEmoji, userIDs: [String]) {
        self.emoji = emoji
        self.userIDs = userIDs
        self.count = userIDs.count
    }

    /// For legacy posts where only an aggregate count survived.
    init(emoji: ReactionEmoji, count: Int) {
        self.emoji = emoji
        self.userIDs = []
        self.count = count
    }
}

// MARK: - Collection Helpers

extension Array where Element == Reaction {
    /// Groups by emoji, most popular first. Ties break on the canonical emoji
    /// order so the bar doesn't reshuffle between renders.
    var grouped: [ReactionGroup] {
        var byEmoji: [ReactionEmoji: [String]] = [:]
        for reaction in self {
            byEmoji[reaction.emoji, default: []].append(reaction.userID)
        }

        let order = ReactionEmoji.allCases
        return byEmoji
            .map { ReactionGroup(emoji: $0.key, userIDs: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                let lhsIndex = order.firstIndex(of: lhs.emoji) ?? order.count
                let rhsIndex = order.firstIndex(of: rhs.emoji) ?? order.count
                return lhsIndex < rhsIndex
            }
    }

    func emoji(for userID: String) -> ReactionEmoji? {
        first { $0.userID == userID }?.emoji
    }

    /// Replaces `userID`'s reaction, or removes it when `emoji` is nil.
    func settingReaction(_ emoji: ReactionEmoji?, for userID: String) -> [Reaction] {
        var updated = filter { $0.userID != userID }
        if let emoji {
            updated.append(Reaction(userID: userID, emoji: emoji))
        }
        return updated
    }
}
