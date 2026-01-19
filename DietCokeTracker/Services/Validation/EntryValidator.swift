import Foundation

/// Centralized validation logic for drink entries to prevent abuse
struct EntryValidator {

    // MARK: - Configuration

    /// Minimum seconds between entries (2 minutes)
    static let minimumEntryInterval: TimeInterval = 120

    /// Maximum ounces per single entry (1 gallon)
    static let maxOuncesPerEntry: Double = 128

    /// Minimum ounces per entry
    static let minOuncesPerEntry: Double = 1

    /// Maximum ounces allowed per day
    static let maxOuncesPerDay: Double = 500

    /// Maximum hours in past for timestamp
    static let maxHoursInPast: Int = 24

    /// Maximum minutes in future for timestamp
    static let maxMinutesInFuture: Int = 5

    /// Duplicate detection window in seconds (2 minutes)
    static let duplicateWindowSeconds: TimeInterval = 120

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?

        static func valid() -> ValidationResult {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        static func invalid(_ message: String) -> ValidationResult {
            ValidationResult(isValid: false, errorMessage: message)
        }
    }

    // MARK: - Rate Limiting

    /// Check if user can add a new entry based on rate limits
    static func canAddEntry(
        lastEntryTime: Date?,
        now: Date = Date()
    ) -> ValidationResult {
        // Check minimum interval between entries
        if let lastTime = lastEntryTime {
            let elapsed = now.timeIntervalSince(lastTime)
            if elapsed < minimumEntryInterval {
                return .invalid("Please wait a moment before adding another drink.")
            }
        }

        return .valid()
    }

    // MARK: - Timestamp Validation

    /// Validate that a timestamp is within acceptable bounds
    static func validateTimestamp(_ date: Date, now: Date = Date()) -> ValidationResult {
        let maxFutureDate = now.addingTimeInterval(TimeInterval(maxMinutesInFuture * 60))
        let maxPastDate = now.addingTimeInterval(TimeInterval(-maxHoursInPast * 3600))

        if date > maxFutureDate {
            return .invalid("Time cannot be more than \(maxMinutesInFuture) minutes in the future")
        }

        if date < maxPastDate {
            return .invalid("Time cannot be more than \(maxHoursInPast) hours in the past")
        }

        return .valid()
    }

    // MARK: - Ounces Validation

    /// Validate custom ounces amount
    static func validateOunces(_ ounces: Double) -> ValidationResult {
        if ounces < minOuncesPerEntry {
            return .invalid("Minimum \(Int(minOuncesPerEntry)) oz per entry")
        }

        if ounces > maxOuncesPerEntry {
            return .invalid("Maximum \(Int(maxOuncesPerEntry)) oz per entry")
        }

        return .valid()
    }

    /// Check if adding more ounces would exceed daily limit
    static func validateDailyOunces(currentDailyOunces: Double, newOunces: Double) -> ValidationResult {
        let total = currentDailyOunces + newOunces
        if total > maxOuncesPerDay {
            let remaining = maxOuncesPerDay - currentDailyOunces
            if remaining <= 0 {
                return .invalid("Daily limit of \(Int(maxOuncesPerDay)) oz reached")
            }
            return .invalid("Adding \(Int(newOunces)) oz would exceed daily limit. Max \(Int(remaining)) oz remaining.")
        }
        return .valid()
    }

    // MARK: - Duplicate Detection

    /// Check if entry would be a duplicate of recent entries
    static func isDuplicate(
        ounces: Double,
        type: DrinkType,
        timestamp: Date,
        existingEntries: [DrinkEntry],
        now: Date = Date()
    ) -> ValidationResult {
        let windowStart = now.addingTimeInterval(-duplicateWindowSeconds)

        let recentEntries = existingEntries.filter { entry in
            entry.timestamp >= windowStart
        }

        for entry in recentEntries {
            // Check for same ounces and type within window
            if entry.ounces == ounces && entry.type == type {
                return .invalid("Duplicate entry detected. Wait a few minutes before adding the same drink.")
            }
        }

        return .valid()
    }

    // MARK: - Pattern Detection (for leaderboard)

    /// Detect suspicious patterns that might indicate abuse
    static func detectSuspiciousPatterns(entries: [DrinkEntry]) -> SuspiciousPatternResult {
        var flags: [String] = []

        let now = Date()
        let last24h = entries.filter {
            $0.timestamp > now.addingTimeInterval(-86400)
        }

        // Flag 1: Too many entries in 24 hours
        if last24h.count > 20 {
            flags.append("High entry volume (\(last24h.count) in 24h)")
        }

        // Flag 2: Too many ounces in 24 hours
        let dailyOunces = last24h.reduce(0.0) { $0 + $1.ounces }
        if dailyOunces > 300 {
            flags.append("High ounces (\(Int(dailyOunces)) oz in 24h)")
        }

        // Flag 3: Entries with unrealistic ounces
        let highOunceEntries = entries.filter { $0.ounces > 100 }
        if highOunceEntries.count > 5 {
            flags.append("Multiple high-oz entries (\(highOunceEntries.count))")
        }

        // Flag 4: Rapid-fire entries (multiple entries within 1 minute)
        let rapidEntries = findRapidFireEntries(entries)
        if rapidEntries > 3 {
            flags.append("Rapid-fire entries detected")
        }

        // Flag 5: Unusual time distribution (all entries at same time)
        if hasUnusualTimeDistribution(entries) {
            flags.append("Unusual entry timing")
        }

        return SuspiciousPatternResult(
            isSuspicious: !flags.isEmpty,
            flags: flags,
            confidenceScore: calculateConfidenceScore(flags.count, entryCount: entries.count)
        )
    }

    private static func findRapidFireEntries(_ entries: [DrinkEntry]) -> Int {
        guard entries.count > 1 else { return 0 }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        var rapidCount = 0

        for i in 1..<sorted.count {
            let timeDiff = sorted[i].timestamp.timeIntervalSince(sorted[i-1].timestamp)
            if timeDiff < 60 { // Less than 1 minute apart
                rapidCount += 1
            }
        }

        return rapidCount
    }

    private static func hasUnusualTimeDistribution(_ entries: [DrinkEntry]) -> Bool {
        guard entries.count >= 10 else { return false }

        let calendar = Calendar.current
        let hours = entries.map { calendar.component(.hour, from: $0.timestamp) }

        // Check if more than 80% of entries are in the same hour
        let hourCounts = Dictionary(grouping: hours) { $0 }.mapValues { $0.count }
        let maxCount = hourCounts.values.max() ?? 0

        return Double(maxCount) / Double(entries.count) > 0.8
    }

    private static func calculateConfidenceScore(_ flagCount: Int, entryCount: Int) -> Double {
        // More flags = higher confidence it's abuse
        // But also consider entry count (new users might trigger some flags legitimately)
        let baseScore = Double(flagCount) * 0.25
        let adjustment = entryCount > 50 ? 0.1 : 0 // Higher bar for established users
        return min(1.0, baseScore + adjustment)
    }
}

// MARK: - Supporting Types

struct SuspiciousPatternResult {
    let isSuspicious: Bool
    let flags: [String]
    let confidenceScore: Double // 0.0 to 1.0, higher = more confident it's abuse

    var description: String {
        if isSuspicious {
            return "Suspicious: " + flags.joined(separator: ", ")
        }
        return "Normal activity"
    }
}
