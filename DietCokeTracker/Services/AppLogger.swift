import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "co.brevinb.fridgecig"

    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let friends = Logger(subsystem: subsystem, category: "Friends")
    static let activity = Logger(subsystem: subsystem, category: "Activity")
    static let healthKit = Logger(subsystem: subsystem, category: "HealthKit")
    static let watch = Logger(subsystem: subsystem, category: "Watch")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let store = Logger(subsystem: subsystem, category: "Store")
    static let photos = Logger(subsystem: subsystem, category: "Photos")
    static let purchases = Logger(subsystem: subsystem, category: "Purchases")
    static let identity = Logger(subsystem: subsystem, category: "Identity")
    static let general = Logger(subsystem: subsystem, category: "General")
}
