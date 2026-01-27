import Foundation
import SwiftUI

// MARK: - Weekly Recap

struct WeeklyRecap: Identifiable, Codable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    let totalDrinks: Int
    let totalOunces: Double
    let mostPopularType: DrinkType?
    let mostPopularTypeCount: Int
    let uniqueTypesCount: Int
    let averagePerDay: Double
    let streakStatus: StreakStatus
    let comparison: WeekComparison?
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        totalDrinks: Int,
        totalOunces: Double,
        mostPopularType: DrinkType?,
        mostPopularTypeCount: Int,
        uniqueTypesCount: Int,
        averagePerDay: Double,
        streakStatus: StreakStatus,
        comparison: WeekComparison?,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalDrinks = totalDrinks
        self.totalOunces = totalOunces
        self.mostPopularType = mostPopularType
        self.mostPopularTypeCount = mostPopularTypeCount
        self.uniqueTypesCount = uniqueTypesCount
        self.averagePerDay = averagePerDay
        self.streakStatus = streakStatus
        self.comparison = comparison
        self.generatedAt = generatedAt
    }

    // MARK: - Computed Properties

    var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekStartDate)
        let end = formatter.string(from: weekEndDate)
        return "\(start) - \(end)"
    }

    var yearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: weekStartDate)
    }

    var funFact: String {
        // Convert ounces to cans (12oz each)
        let cansEquivalent = totalOunces / 12.0
        if cansEquivalent >= 10 {
            return "That's \(Int(cansEquivalent)) cans worth of refreshment!"
        } else if cansEquivalent >= 5 {
            return "You enjoyed about \(Int(cansEquivalent)) cans this week!"
        } else if totalOunces >= 100 {
            return "You sipped \(String(format: "%.0f", totalOunces)) oz of DC this week!"
        } else {
            return "Every sip counts!"
        }
    }

    var summaryEmoji: String {
        switch totalDrinks {
        case 0: return "😴"
        case 1...5: return "🥤"
        case 6...10: return "💪"
        case 11...20: return "🔥"
        case 21...35: return "⚡️"
        default: return "🏆"
        }
    }
}

// MARK: - Streak Status

struct StreakStatus: Codable {
    let currentStreak: Int
    let wasStreakMaintained: Bool
    let streakChange: Int // Positive if increased, negative if broken, 0 if maintained

    var statusText: String {
        if !wasStreakMaintained {
            return "Streak reset"
        } else if streakChange > 0 {
            return "+\(streakChange) days"
        } else {
            return "Maintained"
        }
    }

    var statusColor: Color {
        if !wasStreakMaintained {
            return .red
        } else if streakChange > 0 {
            return .green
        } else {
            return .orange
        }
    }
}

// MARK: - Week Comparison

struct WeekComparison: Codable {
    let drinksDelta: Int        // Positive = more than last week
    let ouncesDelta: Double
    let percentageChange: Double

    var trendIcon: String {
        if drinksDelta > 0 {
            return "arrow.up.right"
        } else if drinksDelta < 0 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }

    var trendColor: Color {
        if drinksDelta > 0 {
            return .green
        } else if drinksDelta < 0 {
            return .orange
        } else {
            return .gray
        }
    }

    var comparisonText: String {
        let absDelta = abs(drinksDelta)
        if drinksDelta > 0 {
            return "+\(absDelta) from last week"
        } else if drinksDelta < 0 {
            return "-\(absDelta) from last week"
        } else {
            return "Same as last week"
        }
    }
}

// MARK: - Weekly Recap Card Theme

enum RecapCardTheme: String, CaseIterable, Identifiable {
    case classic
    case dark
    case vibrant

    var id: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .classic: return Color.dietCokeRed
        case .dark: return Color(red: 0.1, green: 0.1, blue: 0.15)
        case .vibrant: return Color(red: 0.2, green: 0.1, blue: 0.4)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .classic, .dark, .vibrant: return .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .classic: return .white.opacity(0.8)
        case .dark: return Color(white: 0.7)
        case .vibrant: return Color(red: 0.8, green: 0.7, blue: 1.0)
        }
    }

    var accentColor: Color {
        switch self {
        case .classic: return .white
        case .dark: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .vibrant: return Color(red: 1.0, green: 0.5, blue: 0.8)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .classic:
            return [Color.dietCokeRed, Color.dietCokeRed.opacity(0.8)]
        case .dark:
            return [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.1)]
        case .vibrant:
            return [Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 0.2, green: 0.1, blue: 0.4)]
        }
    }
}
