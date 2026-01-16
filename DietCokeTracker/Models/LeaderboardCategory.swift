import Foundation
import SwiftUI

enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case streak = "Streak"
    case weeklyDrinks = "Weekly DCs"
    case weeklyOunces = "Weekly oz"
    case monthlyDrinks = "Monthly DCs"
    case monthlyOunces = "Monthly oz"
    case allTimeDrinks = "All-Time DCs"
    case allTimeOunces = "All-Time oz"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .streak:
            return "flame.fill"
        case .weeklyDrinks, .monthlyDrinks, .allTimeDrinks:
            return "cup.and.saucer.fill"
        case .weeklyOunces, .monthlyOunces, .allTimeOunces:
            return "drop.fill"
        }
    }

    var sortKey: String {
        switch self {
        case .streak: return "currentStreak"
        case .weeklyDrinks: return "weeklyDrinks"
        case .weeklyOunces: return "weeklyOunces"
        case .monthlyDrinks: return "monthlyDrinks"
        case .monthlyOunces: return "monthlyOunces"
        case .allTimeDrinks: return "allTimeDrinks"
        case .allTimeOunces: return "allTimeOunces"
        }
    }

    var unit: String {
        switch self {
        case .streak:
            return "days"
        case .weeklyDrinks, .monthlyDrinks, .allTimeDrinks:
            return "DCs"
        case .weeklyOunces, .monthlyOunces, .allTimeOunces:
            return "oz"
        }
    }

    func value(from profile: UserProfile) -> Double {
        switch self {
        case .streak: return Double(profile.currentStreak)
        case .weeklyDrinks: return Double(profile.weeklyDrinks)
        case .weeklyOunces: return profile.weeklyOunces
        case .monthlyDrinks: return Double(profile.monthlyDrinks)
        case .monthlyOunces: return profile.monthlyOunces
        case .allTimeDrinks: return Double(profile.allTimeDrinks)
        case .allTimeOunces: return profile.allTimeOunces
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .streak, .weeklyDrinks, .monthlyDrinks, .allTimeDrinks:
            return String(format: "%.0f", value)
        case .weeklyOunces, .monthlyOunces, .allTimeOunces:
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let userID: String
    let displayName: String
    let rank: Int
    let value: Double
    let category: LeaderboardCategory
    let isCurrentUser: Bool
    let isFriend: Bool

    init(from profile: UserProfile, rank: Int, category: LeaderboardCategory, currentUserID: String?, friendIDs: Set<String>) {
        self.id = profile.id
        self.userID = profile.userIDString
        self.displayName = profile.displayName
        self.rank = rank
        self.value = category.value(from: profile)
        self.category = category
        self.isCurrentUser = profile.userIDString == currentUserID
        self.isFriend = friendIDs.contains(profile.userIDString)
    }

    var formattedValue: String {
        category.formattedValue(value)
    }
}

// MARK: - Leaderboard Scope

enum LeaderboardScope: String, CaseIterable {
    case friends = "Friends"
    case global = "Global"
}
