import Foundation
import SwiftUI
import UIKit

// MARK: - Shareable Content Protocol

/// Protocol that defines content that can be shared as an image card
protocol ShareableContent: Identifiable {
    /// The type of shareable content
    var contentType: ShareContentType { get }

    /// Primary title displayed prominently on the card
    var shareTitle: String { get }

    /// Secondary subtitle or tagline
    var shareSubtitle: String { get }

    /// Main value or statistic to highlight
    var shareValue: String { get }

    /// Icon name (SF Symbol) for the card
    var shareIcon: String { get }

    /// Date associated with the content
    var shareDate: Date { get }

    /// Optional username for attribution
    var shareUsername: String? { get }

    /// Additional stats to display (optional)
    var shareStats: [ShareStat] { get }

    /// Fun fact or additional context (optional)
    var shareFunFact: String? { get }
}

// MARK: - Share Content Type

enum ShareContentType: String, Codable {
    case milestone
    case weeklyRecap
    case achievement
    case drinkLog

    var displayName: String {
        switch self {
        case .milestone: return "Milestone"
        case .weeklyRecap: return "Weekly Recap"
        case .achievement: return "Achievement"
        case .drinkLog: return "Drink Log"
        }
    }

    var defaultIcon: String {
        switch self {
        case .milestone: return "trophy.fill"
        case .weeklyRecap: return "calendar"
        case .achievement: return "star.fill"
        case .drinkLog: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Share Stat

/// A single statistic to display on a share card
struct ShareStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String?

    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }
}

// MARK: - Default Implementation

extension ShareableContent {
    var shareStats: [ShareStat] { [] }
    var shareFunFact: String? { nil }
    var shareUsername: String? { nil }
}

// MARK: - MilestoneCard Conformance

extension MilestoneCard: ShareableContent {
    var contentType: ShareContentType { .milestone }

    var shareTitle: String { title }

    var shareSubtitle: String { subtitle }

    var shareValue: String { value }

    var shareIcon: String { icon }

    var shareDate: Date { createdAt }

    var shareUsername: String? { username }

    var shareStats: [ShareStat] {
        var stats: [ShareStat] = []

        if let rarity = badgeRarity {
            stats.append(ShareStat(label: "Rarity", value: rarity.displayName, icon: "sparkles"))
        }

        return stats
    }
}

// MARK: - WeeklyRecap Conformance

extension WeeklyRecap: ShareableContent {
    var contentType: ShareContentType { .weeklyRecap }

    var shareTitle: String { "Weekly Recap" }

    var shareSubtitle: String { weekRangeText }

    var shareValue: String { "\(totalDrinks)" }

    var shareIcon: String { "calendar" }

    var shareDate: Date { generatedAt }

    var shareUsername: String? { nil }

    var shareStats: [ShareStat] {
        var stats: [ShareStat] = [
            ShareStat(label: "Total Volume", value: "\(Int(totalOunces)) oz", icon: "drop.fill"),
            ShareStat(label: "Daily Avg", value: String(format: "%.1f", averagePerDay), icon: "chart.bar.fill")
        ]

        if let type = mostPopularType {
            stats.append(ShareStat(label: "Favorite", value: type.shortName, icon: type.icon))
        }

        if streakStatus.currentStreak > 0 {
            stats.append(ShareStat(label: "Streak", value: "\(streakStatus.currentStreak) days", icon: "flame.fill"))
        }

        return stats
    }

    var shareFunFact: String? { funFact }
}

// MARK: - DrinkEntry Conformance

extension DrinkEntry: ShareableContent {
    var contentType: ShareContentType { .drinkLog }

    var shareTitle: String {
        brand.shortName
    }

    var shareSubtitle: String {
        type.rawValue
    }

    var shareValue: String {
        "\(Int(ounces)) oz"
    }

    var shareIcon: String {
        type.icon
    }

    var shareDate: Date {
        timestamp
    }

    var shareUsername: String? { nil }

    var shareStats: [ShareStat] {
        var stats: [ShareStat] = []

        // Add rating if available
        if let rating = rating {
            stats.append(ShareStat(label: "Rating", value: rating.displayName, icon: "star.fill"))
        }

        // Add special edition if available
        if let special = specialEdition {
            stats.append(ShareStat(label: "Edition", value: special.rawValue, icon: "sparkles"))
        }

        return stats
    }

    var shareFunFact: String? {
        note
    }

    // MARK: - Photo Support

    /// Returns the photo image if available
    var sharePhoto: UIImage? {
        guard let filename = photoFilename else { return nil }
        return PhotoStorage.loadPhoto(filename: filename)
    }
}
