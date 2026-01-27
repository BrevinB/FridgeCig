import Foundation
import SwiftUI

// MARK: - Milestone Type

enum MilestoneType: String, Codable {
    case badge           // Badge unlock
    case streak          // Streak milestone (7, 30, 100, 365 days)
    case drinkCount      // Drink count milestone (100, 500, 1000, etc.)

    var celebrationEmoji: String {
        switch self {
        case .badge: return "🏆"
        case .streak: return "🔥"
        case .drinkCount: return "🥤"
        }
    }
}

// MARK: - Card Theme

enum CardTheme: String, Codable, CaseIterable, Identifiable {
    case classic     // Free - Diet Coke red
    case midnight    // Premium - Dark mode
    case neon        // Premium - Vibrant gradients
    case retro       // Premium - Vintage style
    case minimal     // Premium - Clean white

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var isPremium: Bool {
        self != .classic
    }

    var backgroundColor: Color {
        switch self {
        case .classic: return Color.dietCokeRed
        case .midnight: return Color(red: 0.1, green: 0.1, blue: 0.15)
        case .neon: return Color(red: 0.1, green: 0.05, blue: 0.2)
        case .retro: return Color(red: 0.95, green: 0.9, blue: 0.85)
        case .minimal: return .white
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .classic, .midnight, .neon: return .white
        case .retro: return Color(red: 0.3, green: 0.2, blue: 0.1)
        case .minimal: return .black
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .classic: return .white.opacity(0.8)
        case .midnight: return Color(red: 0.6, green: 0.6, blue: 0.7)
        case .neon: return Color(red: 0.8, green: 0.6, blue: 1.0)
        case .retro: return Color(red: 0.5, green: 0.4, blue: 0.3)
        case .minimal: return .gray
        }
    }

    var accentColor: Color {
        switch self {
        case .classic: return .white
        case .midnight: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .neon: return Color(red: 1.0, green: 0.3, blue: 0.8)
        case .retro: return Color(red: 0.8, green: 0.4, blue: 0.2)
        case .minimal: return .dietCokeRed
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .classic:
            return [Color.dietCokeRed, Color.dietCokeRed.opacity(0.8)]
        case .midnight:
            return [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.1)]
        case .neon:
            return [Color(red: 0.3, green: 0.1, blue: 0.5), Color(red: 0.1, green: 0.05, blue: 0.3)]
        case .retro:
            return [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.9, green: 0.85, blue: 0.8)]
        case .minimal:
            return [.white, Color(white: 0.98)]
        }
    }

    var icon: String {
        switch self {
        case .classic: return "paintbrush.fill"
        case .midnight: return "moon.stars.fill"
        case .neon: return "sparkles"
        case .retro: return "clock.arrow.circlepath"
        case .minimal: return "square.fill"
        }
    }
}

// MARK: - Milestone Card

struct MilestoneCard: Identifiable, Codable, Equatable {
    let id: UUID
    let type: MilestoneType
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let createdAt: Date

    // Optional badge info
    let badgeId: String?
    let badgeRarity: BadgeRarity?

    // User info for sharing
    var username: String?

    init(
        id: UUID = UUID(),
        type: MilestoneType,
        title: String,
        subtitle: String,
        value: String,
        icon: String,
        createdAt: Date = Date(),
        badgeId: String? = nil,
        badgeRarity: BadgeRarity? = nil,
        username: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.createdAt = createdAt
        self.badgeId = badgeId
        self.badgeRarity = badgeRarity
        self.username = username
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }

    // MARK: - Factory Methods

    static func forBadge(_ badge: Badge, username: String? = nil) -> MilestoneCard {
        MilestoneCard(
            type: .badge,
            title: "Badge Unlocked!",
            subtitle: badge.title,
            value: badge.description,
            icon: badge.icon,
            badgeId: badge.id,
            badgeRarity: badge.rarity,
            username: username
        )
    }

    static func forStreak(_ days: Int, username: String? = nil) -> MilestoneCard {
        let subtitle: String
        switch days {
        case 7: subtitle = "Week Warrior"
        case 30: subtitle = "Monthly Master"
        case 100: subtitle = "Century Club"
        case 365: subtitle = "Year Legend"
        default: subtitle = "Streak Milestone"
        }

        return MilestoneCard(
            type: .streak,
            title: "\(days) Day Streak!",
            subtitle: subtitle,
            value: "You've logged DCs for \(days) days straight!",
            icon: "flame.fill",
            username: username
        )
    }

    static func forDrinkCount(_ count: Int, username: String? = nil) -> MilestoneCard {
        let subtitle: String
        switch count {
        case 100: subtitle = "Century Sipper"
        case 500: subtitle = "DC Devotee"
        case 1000: subtitle = "Legendary Status"
        case 2500: subtitle = "Elite Tier"
        case 5000: subtitle = "Hall of Fame"
        default: subtitle = "Milestone Reached"
        }

        return MilestoneCard(
            type: .drinkCount,
            title: "\(count) DCs!",
            subtitle: subtitle,
            value: "You've logged \(count) Diet Cokes!",
            icon: "flask.fill",
            username: username
        )
    }
}

// MARK: - Milestone Thresholds

struct MilestoneThresholds {
    static let streakMilestones = [7, 30, 100, 365]
    static let drinkCountMilestones = [100, 500, 1000, 2500, 5000]

    static func isStreakMilestone(_ days: Int) -> Bool {
        streakMilestones.contains(days)
    }

    static func isDrinkCountMilestone(_ count: Int) -> Bool {
        drinkCountMilestones.contains(count)
    }

    static func nextStreakMilestone(current: Int) -> Int? {
        streakMilestones.first { $0 > current }
    }

    static func nextDrinkCountMilestone(current: Int) -> Int? {
        drinkCountMilestones.first { $0 > current }
    }
}
