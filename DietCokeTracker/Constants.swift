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
    enum AppLinks {
        /// Public download link appended to every shared card's caption so each
        /// share is a tappable acquisition channel.
        static let shareDownloadURL = "https://apps.apple.com/app/id6757887069"
    }
}
