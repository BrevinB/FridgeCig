import Foundation
import HealthKit
import os

/// Manages HealthKit integration for logging caffeine intake
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    /// Caffeine per 12oz of DC (mg)
    static let caffeinePerTwelveOunces: Double = Constants.HealthKit.caffeinePerTwelveOunces

    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()

    /// User preference for auto-logging caffeine
    @Published var isAutoLogEnabled: Bool {
        didSet {
            UserDefaults(suiteName: SharedDataManager.appGroupID)?
                .set(isAutoLogEnabled, forKey: "healthKitAutoLogEnabled")
        }
    }

    private let caffeineType = HKQuantityType(.dietaryCaffeine)

    private init() {
        // Load auto-log preference
        self.isAutoLogEnabled = UserDefaults(suiteName: SharedDataManager.appGroupID)?
            .bool(forKey: "healthKitAutoLogEnabled") ?? false

        // Check current authorization status
        Task {
            await updateAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request HealthKit authorization for caffeine data
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        let typesToWrite: Set<HKSampleType> = [caffeineType]
        let typesToRead: Set<HKObjectType> = [caffeineType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await updateAuthorizationStatus()
    }

    /// Update the current authorization status
    func updateAuthorizationStatus() async {
        guard isHealthKitAvailable else {
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }

        authorizationStatus = healthStore.authorizationStatus(for: caffeineType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }

    // MARK: - Caffeine Logging

    /// Calculate caffeine content from ounces
    static func calculateCaffeine(ounces: Double, brand: BeverageBrand) -> Double {
        // Check if caffeine-free
        if brand.isCaffeineFree {
            return 0
        }
        // DC has ~46mg caffeine per 12oz
        return (ounces / 12.0) * caffeinePerTwelveOunces
    }

    /// Log caffeine intake to HealthKit
    func logCaffeine(mg: Double, date: Date, entryID: String? = nil) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        guard mg > 0 else {
            // Don't log 0mg (caffeine-free drinks)
            return
        }

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: false,
            "source": "FridgeCig"
        ]
        if let entryID = entryID {
            metadata["entryID"] = entryID
        }

        let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: mg)
        let sample = HKQuantitySample(
            type: caffeineType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: metadata
        )

        try await healthStore.save(sample)
        AppLogger.healthKit.info("Logged \(mg)mg caffeine at \(date)")
    }

    /// Log caffeine from a drink entry
    func logDrink(entry: DrinkEntry) async throws {
        guard isAutoLogEnabled else { return }
        let caffeineAmount = Self.calculateCaffeine(ounces: entry.ounces, brand: entry.brand)
        try await logCaffeine(mg: caffeineAmount, date: entry.timestamp, entryID: entry.id.uuidString)
    }

    /// Log caffeine from drink parameters (used when adding drinks)
    func logDrink(ounces: Double, brand: BeverageBrand, date: Date = Date()) async throws {
        guard isAutoLogEnabled else { return }
        let caffeineAmount = Self.calculateCaffeine(ounces: ounces, brand: brand)
        try await logCaffeine(mg: caffeineAmount, date: date)
    }

    // MARK: - Delete Caffeine Data

    /// Delete caffeine sample for a drink entry
    func deleteDrink(entry: DrinkEntry) async throws {
        guard isAuthorized else { return }
        guard isAutoLogEnabled else { return }

        // Find and delete samples matching this entry
        let samples = try await findSamples(forEntryID: entry.id.uuidString, date: entry.timestamp)

        if !samples.isEmpty {
            try await healthStore.delete(samples)
            AppLogger.healthKit.info("Deleted \(samples.count) caffeine sample(s) for entry \(entry.id)")
        }
    }

    /// Find caffeine samples for a specific entry
    private func findSamples(forEntryID entryID: String, date: Date) async throws -> [HKSample] {
        // Search within a small time window around the entry timestamp
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .second, value: -1, to: date) ?? date
        let endDate = calendar.date(byAdding: .second, value: 1, to: date) ?? date

        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: caffeineType,
                predicate: datePredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                // Filter to samples from FridgeCig with matching entry ID
                let matchingSamples = (samples ?? []).filter { sample in
                    guard let metadata = sample.metadata else { return false }
                    let isFromApp = metadata["source"] as? String == "FridgeCig"
                    let matchesEntry = metadata["entryID"] as? String == entryID
                    return isFromApp && matchesEntry
                }

                continuation.resume(returning: matchingSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Query Caffeine Data

    /// Get today's total caffeine logged via this app
    func getTodayCaffeine() async throws -> Double {
        guard isAuthorized else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caffeineType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = result?.sumQuantity()?.doubleValue(for: .gramUnit(with: .milli)) ?? 0
                continuation.resume(returning: sum)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "Please enable HealthKit access in Settings."
        case .saveFailed:
            return "Failed to save to HealthKit."
        }
    }
}
