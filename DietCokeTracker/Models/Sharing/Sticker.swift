import Foundation
import SwiftUI

// MARK: - Sticker

/// A decorative sticker that can be placed on share cards
struct Sticker: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let category: StickerCategory
    let name: String
    let emoji: String?
    let sfSymbol: String?
    let isPremium: Bool

    init(
        id: String,
        category: StickerCategory,
        name: String,
        emoji: String? = nil,
        sfSymbol: String? = nil,
        isPremium: Bool = true
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.emoji = emoji
        self.sfSymbol = sfSymbol
        self.isPremium = isPremium
    }

    var displayContent: String {
        emoji ?? ""
    }

    var hasEmoji: Bool {
        emoji != nil
    }

    var hasSFSymbol: Bool {
        sfSymbol != nil
    }
}

// MARK: - Sticker Category

enum StickerCategory: String, CaseIterable, Codable {
    case drinks
    case celebrations
    case reactions
    case seasonal
    case decorative

    var displayName: String {
        switch self {
        case .drinks: return "Drinks"
        case .celebrations: return "Celebrations"
        case .reactions: return "Reactions"
        case .seasonal: return "Seasonal"
        case .decorative: return "Decorative"
        }
    }

    var icon: String {
        switch self {
        case .drinks: return "cup.and.saucer.fill"
        case .celebrations: return "party.popper.fill"
        case .reactions: return "face.smiling.fill"
        case .seasonal: return "leaf.fill"
        case .decorative: return "star.fill"
        }
    }
}

// MARK: - Sticker Library

struct StickerLibrary {
    static let all: [Sticker] = drinks + celebrations + reactions + seasonal + decorative

    static let drinks: [Sticker] = [
        Sticker(id: "drink_soda", category: .drinks, name: "Soda", emoji: "🥤", isPremium: false),
        Sticker(id: "drink_cup", category: .drinks, name: "Cup", emoji: "🫗", isPremium: false),
        Sticker(id: "drink_ice", category: .drinks, name: "Ice", emoji: "🧊", isPremium: true),
        Sticker(id: "drink_can", category: .drinks, name: "Can", sfSymbol: "cylinder.fill", isPremium: true),
        Sticker(id: "drink_bottle", category: .drinks, name: "Bottle", emoji: "🍾", isPremium: true),
        Sticker(id: "drink_bubbles", category: .drinks, name: "Bubbles", sfSymbol: "bubbles.and.sparkles.fill", isPremium: true)
    ]

    static let celebrations: [Sticker] = [
        Sticker(id: "celeb_party", category: .celebrations, name: "Party", emoji: "🎉", isPremium: false),
        Sticker(id: "celeb_confetti", category: .celebrations, name: "Confetti", emoji: "🎊", isPremium: true),
        Sticker(id: "celeb_trophy", category: .celebrations, name: "Trophy", emoji: "🏆", isPremium: true),
        Sticker(id: "celeb_medal", category: .celebrations, name: "Medal", emoji: "🥇", isPremium: true),
        Sticker(id: "celeb_star", category: .celebrations, name: "Star", emoji: "⭐️", isPremium: false),
        Sticker(id: "celeb_sparkles", category: .celebrations, name: "Sparkles", emoji: "✨", isPremium: true),
        Sticker(id: "celeb_fire", category: .celebrations, name: "Fire", emoji: "🔥", isPremium: true),
        Sticker(id: "celeb_crown", category: .celebrations, name: "Crown", emoji: "👑", isPremium: true)
    ]

    static let reactions: [Sticker] = [
        Sticker(id: "react_love", category: .reactions, name: "Love", emoji: "❤️", isPremium: false),
        Sticker(id: "react_wow", category: .reactions, name: "Wow", emoji: "😮", isPremium: true),
        Sticker(id: "react_cool", category: .reactions, name: "Cool", emoji: "😎", isPremium: true),
        Sticker(id: "react_strong", category: .reactions, name: "Strong", emoji: "💪", isPremium: true),
        Sticker(id: "react_hundred", category: .reactions, name: "100", emoji: "💯", isPremium: true),
        Sticker(id: "react_thumbsup", category: .reactions, name: "Thumbs Up", emoji: "👍", isPremium: false),
        Sticker(id: "react_mindblown", category: .reactions, name: "Mind Blown", emoji: "🤯", isPremium: true)
    ]

    static let seasonal: [Sticker] = [
        Sticker(id: "season_sun", category: .seasonal, name: "Sun", emoji: "☀️", isPremium: true),
        Sticker(id: "season_snowflake", category: .seasonal, name: "Snowflake", emoji: "❄️", isPremium: true),
        Sticker(id: "season_leaf", category: .seasonal, name: "Leaf", emoji: "🍂", isPremium: true),
        Sticker(id: "season_flower", category: .seasonal, name: "Flower", emoji: "🌸", isPremium: true),
        Sticker(id: "season_palm", category: .seasonal, name: "Palm", emoji: "🌴", isPremium: true),
        Sticker(id: "season_fireworks", category: .seasonal, name: "Fireworks", emoji: "🎆", isPremium: true)
    ]

    static let decorative: [Sticker] = [
        Sticker(id: "deco_lightning", category: .decorative, name: "Lightning", emoji: "⚡️", isPremium: true),
        Sticker(id: "deco_rainbow", category: .decorative, name: "Rainbow", emoji: "🌈", isPremium: true),
        Sticker(id: "deco_diamond", category: .decorative, name: "Diamond", emoji: "💎", isPremium: true),
        Sticker(id: "deco_rocket", category: .decorative, name: "Rocket", emoji: "🚀", isPremium: true),
        Sticker(id: "deco_arrow", category: .decorative, name: "Arrow", sfSymbol: "arrow.up.right", isPremium: true),
        Sticker(id: "deco_heart_spark", category: .decorative, name: "Sparkling Heart", emoji: "💖", isPremium: true)
    ]

    static func stickers(for category: StickerCategory) -> [Sticker] {
        all.filter { $0.category == category }
    }

    static func freeStickers() -> [Sticker] {
        all.filter { !$0.isPremium }
    }

    static func premiumStickers() -> [Sticker] {
        all.filter { $0.isPremium }
    }
}

// MARK: - Sticker View

struct StickerView: View {
    let sticker: Sticker
    let size: CGFloat

    init(sticker: Sticker, size: CGFloat = 44) {
        self.sticker = sticker
        self.size = size
    }

    var body: some View {
        Group {
            if let emoji = sticker.emoji {
                Text(emoji)
                    .font(.system(size: size * 0.8))
            } else if let symbol = sticker.sfSymbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.6))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
