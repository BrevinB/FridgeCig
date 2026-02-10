#if DEBUG
import Foundation
import SwiftUI

/// Populates the app with curated data optimized for App Store screenshots
@MainActor
class ScreenshotDataManager {

    static let shared = ScreenshotDataManager()

    private init() {}

    // MARK: - Main Entry Point

    func populateScreenshotData(
        drinkStore: DrinkStore,
        badgeStore: BadgeStore,
        activityService: ActivityFeedService,
        friendService: FriendConnectionService
    ) {
        // Clear existing data first
        clearAllData(drinkStore: drinkStore, badgeStore: badgeStore, activityService: activityService, friendService: friendService)

        // Add curated data
        populateDrinkEntries(drinkStore: drinkStore)
        populateBadges(badgeStore: badgeStore)
        populateActivityFeed(activityService: activityService)
        populateFriends(friendService: friendService)
    }

    func clearAllData(
        drinkStore: DrinkStore,
        badgeStore: BadgeStore,
        activityService: ActivityFeedService,
        friendService: FriendConnectionService
    ) {
        drinkStore.clearAllData()
        badgeStore.resetAllBadges()
        activityService.clearTestActivities()
        friendService.clearFakeFriends()
    }

    // MARK: - Drink Entries

    private func populateDrinkEntries(drinkStore: DrinkStore) {
        let calendar = Calendar.current
        let now = Date()

        // Create a 14-day streak with varied, realistic entries
        let drinkPatterns: [(dayOffset: Int, drinks: [(DrinkType, Int, Int)])] = [
            // (dayOffset, [(type, hour, minute)])
            (0, [(.regularCan, 9, 30), (.mcdonaldsMedium, 12, 15), (.bottle20oz, 16, 45)]),
            (1, [(.regularCan, 8, 0), (.fountainMedium, 13, 30)]),
            (2, [(.tallCan, 10, 15), (.chickfilaMedium, 12, 0), (.regularCan, 18, 30)]),
            (3, [(.regularCan, 9, 0), (.mcdonaldsLarge, 14, 0)]),
            (4, [(.bottle20oz, 11, 30), (.regularCan, 17, 0)]),
            (5, [(.regularCan, 8, 45), (.fountainLarge, 12, 30), (.miniCan, 20, 0)]),
            (6, [(.chickfilaLarge, 13, 0), (.regularCan, 19, 30)]),
            (7, [(.regularCan, 9, 15), (.mcdonaldsMedium, 12, 45), (.bottle20oz, 16, 0)]),
            (8, [(.tallCan, 10, 0), (.regularCan, 15, 30)]),
            (9, [(.regularCan, 8, 30), (.fountainMedium, 13, 15), (.regularCan, 18, 0)]),
            (10, [(.mcdonaldsLarge, 12, 0), (.miniCan, 17, 30)]),
            (11, [(.regularCan, 9, 0), (.chickfilaMedium, 13, 0), (.bottle20oz, 19, 0)]),
            (12, [(.regularCan, 10, 30), (.fountainLarge, 14, 15)]),
            (13, [(.bottle20oz, 8, 0), (.regularCan, 12, 30), (.regularCan, 17, 45)]),
        ]

        for pattern in drinkPatterns {
            guard let date = calendar.date(byAdding: .day, value: -pattern.dayOffset, to: now) else { continue }

            for (type, hour, minute) in pattern.drinks {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute

                if let timestamp = calendar.date(from: components) {
                    let entry = DrinkEntry(type: type, timestamp: timestamp)
                    drinkStore.addEntry(entry)
                }
            }
        }

        // Add some older entries for better stats (past month)
        for dayOffset in 15..<45 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            // Skip some days randomly for realism
            if dayOffset % 3 == 0 { continue }

            let count = Int.random(in: 1...3)
            for i in 0..<count {
                let types: [DrinkType] = [.regularCan, .bottle20oz, .mcdonaldsMedium, .fountainMedium, .tallCan]
                let type = types[i % types.count]
                let hour = [9, 12, 15, 18][i % 4]

                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = Int.random(in: 0...59)

                if let timestamp = calendar.date(from: components) {
                    let entry = DrinkEntry(type: type, timestamp: timestamp)
                    drinkStore.addEntry(entry)
                }
            }
        }
    }

    // MARK: - Badges

    private func populateBadges(badgeStore: BadgeStore) {
        // Unlock a curated selection of badges that look impressive
        let badgesToUnlock = [
            // Milestones
            "first_sip",
            "getting_started",
            "regular",
            "enthusiast",

            // Streaks
            "streak_3",
            "streak_7",
            "streak_14",

            // Volume
            "volume_100",
            "volume_500",

            // Variety
            "variety_3",
            "variety_5",

            // Lifestyle (fun ones that look good in screenshots)
            "lunch_break",
            "happy_hour",
            "weekend_warrior",
            "monday_motivation",
            "friday_feeling",
            "double_fisting",
            "triple_threat",
            "breakfast_of_champions",
            "sharing_is_caring",
            "can_collector",
            "mclovin_it",
            "its_not_an_addiction",
        ]

        // Unlock badges with staggered dates for realism
        let calendar = Calendar.current
        let now = Date()

        for (index, badgeId) in badgesToUnlock.enumerated() {
            let daysAgo = min(index * 2, 30)
            if let unlockDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                badgeStore.unlock(badgeId, on: unlockDate)
            }
        }
    }

    // MARK: - Activity Feed

    private func populateActivityFeed(activityService: ActivityFeedService) {
        activityService.isUsingFakeData = true

        let activities: [ActivityItem] = [
            // Recent badge unlocks
            ActivityItem(
                userID: "friend1",
                displayName: "Sarah",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-1800), // 30 min ago
                payload: ActivityPayload(badgeID: "streak_30", badgeTitle: "Monthly Master", badgeIcon: "calendar.badge.checkmark", badgeRarity: .epic),
                cheersCount: 12,
                cheersUserIDs: ["user1", "user2"]
            ),
            ActivityItem(
                userID: "friend2",
                displayName: "Mike",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                payload: ActivityPayload(drinkType: .mcdonaldsLarge, drinkNote: "Perfect fountain ratio", hasPhoto: true),
                cheersCount: 5,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "friend3",
                displayName: "Emma",
                type: .streakMilestone,
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                payload: ActivityPayload(streakDays: 30, streakMessage: "A whole month!"),
                cheersCount: 24,
                cheersUserIDs: ["user1", "user2", "user3"]
            ),
            ActivityItem(
                userID: "friend4",
                displayName: "Jake",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-14400), // 4 hours ago
                payload: ActivityPayload(badgeID: "legend", badgeTitle: "Legend", badgeIcon: "trophy.fill", badgeRarity: .epic),
                cheersCount: 31,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "friend5",
                displayName: "Alex",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-21600), // 6 hours ago
                payload: ActivityPayload(drinkType: .chickfilaLarge, drinkNote: "Lunch break essential", hasPhoto: false),
                cheersCount: 3,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "friend1",
                displayName: "Sarah",
                type: .drinkLog,
                timestamp: Date().addingTimeInterval(-28800), // 8 hours ago
                payload: ActivityPayload(drinkType: .regularCan, drinkNote: nil, hasPhoto: true),
                cheersCount: 7,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "friend6",
                displayName: "Chris",
                type: .streakMilestone,
                timestamp: Date().addingTimeInterval(-43200), // 12 hours ago
                payload: ActivityPayload(streakDays: 7, streakMessage: "One week strong!"),
                cheersCount: 15,
                cheersUserIDs: []
            ),
            ActivityItem(
                userID: "friend2",
                displayName: "Mike",
                type: .badgeUnlock,
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                payload: ActivityPayload(badgeID: "centurion", badgeTitle: "Centurion", badgeIcon: "crown.fill", badgeRarity: .rare),
                cheersCount: 19,
                cheersUserIDs: []
            ),
        ]

        activityService.activities = activities
    }

    // MARK: - Friends

    private func populateFriends(friendService: FriendConnectionService) {
        friendService.addFakeFriends()
    }
}

#endif

