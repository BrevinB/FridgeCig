import Foundation

enum Constants {
    enum RateLimiting {
        static let minimumEntryInterval: TimeInterval = 120
    }
    enum Sync {
        static let activityFeedLimit = 50
        static let maxRetryCount = 5
    }
    enum Streaks {
        static let milestones = [7, 14, 30, 60, 90, 100, 180, 365]
    }
    enum HealthKit {
        static let caffeinePerTwelveOunces: Double = 46
    }
}
