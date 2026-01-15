import Foundation
import SwiftUI

// MARK: - Badge Model

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let type: BadgeType
    let title: String
    let description: String
    let icon: String
    let rarity: BadgeRarity
    var unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var formattedUnlockDate: String? {
        guard let date = unlockedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Badge Type

enum BadgeType: String, Codable, Equatable {
    case milestone
    case streak
    case special
    case variety
    case volume
}

// MARK: - Badge Rarity

enum BadgeRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Special Edition

enum SpecialEdition: String, Codable, CaseIterable, Identifiable {
    case fifa2026 = "FIFA World Cup 2026"
    case summerVibes = "Summer Vibes 2025"
    case holidaySeason = "Holiday Season"
    case retroEdition = "Retro Edition"
    case zeroSugarLime = "Zero Sugar Lime"
    case cherryVanilla = "Cherry Vanilla"
    case starlight = "Starlight"
    case dreamworld = "Dreamworld"
    case marshmello = "Marshmello"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fifa2026: return "soccerball"
        case .summerVibes: return "sun.max.fill"
        case .holidaySeason: return "gift.fill"
        case .retroEdition: return "clock.arrow.circlepath"
        case .zeroSugarLime: return "leaf.fill"
        case .cherryVanilla: return "heart.fill"
        case .starlight: return "star.fill"
        case .dreamworld: return "moon.stars.fill"
        case .marshmello: return "music.note"
        }
    }

    var badgeDescription: String {
        switch self {
        case .fifa2026:
            return "Enjoyed a FIFA World Cup 2026 limited edition Diet Coke"
        case .summerVibes:
            return "Tried the Summer Vibes limited release"
        case .holidaySeason:
            return "Celebrated with a Holiday Season Diet Coke"
        case .retroEdition:
            return "Sipped on a classic Retro Edition"
        case .zeroSugarLime:
            return "Tasted the Zero Sugar Lime variant"
        case .cherryVanilla:
            return "Enjoyed the Cherry Vanilla flavor"
        case .starlight:
            return "Experienced the cosmic Starlight edition"
        case .dreamworld:
            return "Explored the Dreamworld limited flavor"
        case .marshmello:
            return "Vibed with the Marshmello collaboration"
        }
    }

    var rarity: BadgeRarity {
        switch self {
        case .fifa2026, .starlight, .dreamworld, .marshmello:
            return .legendary
        case .summerVibes, .holidaySeason:
            return .epic
        case .retroEdition:
            return .rare
        case .zeroSugarLime, .cherryVanilla:
            return .uncommon
        }
    }

    func toBadge() -> Badge {
        Badge(
            id: "special_\(self.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))",
            type: .special,
            title: rawValue,
            description: badgeDescription,
            icon: icon,
            rarity: rarity,
            unlockedAt: nil
        )
    }
}

// MARK: - All Available Badges

struct BadgeDefinitions {

    // MARK: - Milestone Badges (Count Based)

    static let milestones: [Badge] = [
        Badge(id: "first_sip", type: .milestone, title: "First Sip",
              description: "Log your first Diet Coke", icon: "drop.fill", rarity: .common),
        Badge(id: "getting_started", type: .milestone, title: "Getting Started",
              description: "Log 10 Diet Cokes", icon: "flame.fill", rarity: .common),
        Badge(id: "regular", type: .milestone, title: "Regular",
              description: "Log 25 Diet Cokes", icon: "star.fill", rarity: .uncommon),
        Badge(id: "enthusiast", type: .milestone, title: "Enthusiast",
              description: "Log 50 Diet Cokes", icon: "star.circle.fill", rarity: .uncommon),
        Badge(id: "dedicated", type: .milestone, title: "Dedicated",
              description: "Log 100 Diet Cokes", icon: "medal.fill", rarity: .rare),
        Badge(id: "centurion", type: .milestone, title: "Centurion",
              description: "Log 250 Diet Cokes", icon: "crown.fill", rarity: .rare),
        Badge(id: "legend", type: .milestone, title: "Legend",
              description: "Log 500 Diet Cokes", icon: "trophy.fill", rarity: .epic),
        Badge(id: "ultimate", type: .milestone, title: "Ultimate Fan",
              description: "Log 1000 Diet Cokes", icon: "sparkles", rarity: .legendary),
    ]

    static func milestoneThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "first_sip": return 1
        case "getting_started": return 10
        case "regular": return 25
        case "enthusiast": return 50
        case "dedicated": return 100
        case "centurion": return 250
        case "legend": return 500
        case "ultimate": return 1000
        default: return nil
        }
    }

    // MARK: - Streak Badges

    static let streaks: [Badge] = [
        Badge(id: "streak_3", type: .streak, title: "Three-peat",
              description: "Maintain a 3-day streak", icon: "3.circle.fill", rarity: .common),
        Badge(id: "streak_7", type: .streak, title: "Week Warrior",
              description: "Maintain a 7-day streak", icon: "7.circle.fill", rarity: .uncommon),
        Badge(id: "streak_14", type: .streak, title: "Fortnight Fighter",
              description: "Maintain a 14-day streak", icon: "calendar", rarity: .rare),
        Badge(id: "streak_30", type: .streak, title: "Monthly Master",
              description: "Maintain a 30-day streak", icon: "calendar.badge.checkmark", rarity: .epic),
        Badge(id: "streak_100", type: .streak, title: "Century Streak",
              description: "Maintain a 100-day streak", icon: "bolt.shield.fill", rarity: .legendary),
    ]

    static func streakThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "streak_3": return 3
        case "streak_7": return 7
        case "streak_14": return 14
        case "streak_30": return 30
        case "streak_100": return 100
        default: return nil
        }
    }

    // MARK: - Volume Badges (Ounces Based)

    static let volume: [Badge] = [
        Badge(id: "volume_100", type: .volume, title: "First Gallon",
              description: "Drink 128+ ounces total", icon: "drop.circle.fill", rarity: .common),
        Badge(id: "volume_500", type: .volume, title: "Half Grand",
              description: "Drink 500+ ounces total", icon: "drop.degreesign.fill", rarity: .uncommon),
        Badge(id: "volume_1000", type: .volume, title: "Kiloounce Club",
              description: "Drink 1000+ ounces total", icon: "waterbottle.fill", rarity: .rare),
        Badge(id: "volume_5000", type: .volume, title: "Ocean Sipper",
              description: "Drink 5000+ ounces total", icon: "water.waves", rarity: .epic),
        Badge(id: "volume_10000", type: .volume, title: "Hydration Hero",
              description: "Drink 10000+ ounces total", icon: "hurricane", rarity: .legendary),
    ]

    static func volumeThreshold(for badgeId: String) -> Double? {
        switch badgeId {
        case "volume_100": return 128
        case "volume_500": return 500
        case "volume_1000": return 1000
        case "volume_5000": return 5000
        case "volume_10000": return 10000
        default: return nil
        }
    }

    // MARK: - Variety Badges

    static let variety: [Badge] = [
        Badge(id: "variety_3", type: .variety, title: "Variety Seeker",
              description: "Try 3 different drink types", icon: "square.grid.2x2.fill", rarity: .common),
        Badge(id: "variety_5", type: .variety, title: "Explorer",
              description: "Try 5 different drink types", icon: "map.fill", rarity: .uncommon),
        Badge(id: "variety_10", type: .variety, title: "Adventurer",
              description: "Try 10 different drink types", icon: "safari.fill", rarity: .rare),
        Badge(id: "variety_all", type: .variety, title: "Completionist",
              description: "Try all drink types", icon: "checkmark.seal.fill", rarity: .epic),
    ]

    static func varietyThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "variety_3": return 3
        case "variety_5": return 5
        case "variety_10": return 10
        case "variety_all": return DrinkType.allCases.count
        default: return nil
        }
    }

    // MARK: - Special Edition Badges

    static var specialEditions: [Badge] {
        SpecialEdition.allCases.map { $0.toBadge() }
    }

    // MARK: - All Badges

    static var all: [Badge] {
        milestones + streaks + volume + variety + specialEditions
    }
}
