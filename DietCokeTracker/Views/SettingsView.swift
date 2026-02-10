import SwiftUI
import CloudKit
import UniformTypeIdentifiers
import HealthKit
import os

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var badgeStore: BadgeStore
    @StateObject private var healthKitManager = HealthKitManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeletingAccount = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var showingHealthKitPaywall = false
    @State private var isRequestingHealthKit = false

    #if DEBUG
    @State private var debugTestUserCode: String?
    @State private var isCreatingTestUser = false
    @State private var debugError: String?
    @State private var showingFakeDataAdded = false
    @State private var showingFriendRequestsAdded = false
    @State private var isRunningDiagnostic = false
    @State private var diagnosticResult: String?
    @State private var showingScreenshotDataAdded = false
    #endif

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        themeManager.backgroundColor(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                    // Subscription Section
                    Section {
                        NavigationLink {
                            SubscriptionStatusView()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)

                                    Image(systemName: purchaseService.isPremium ? "crown.fill" : "crown")
                                        .foregroundColor(.dietCokeRed)
                                        .font(.system(size: 16, weight: .medium))
                                }

                                Text(purchaseService.isPremium ? "FridgeCig Pro" : "Upgrade to Pro")
                                    .fontWeight(.medium)

                                Spacer()

                                if purchaseService.isPremium {
                                    Text("Active")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } header: {
                        Text("Subscription")
                    }

                    // Notifications Section
                    Section {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)

                                    Image(systemName: notificationService.isAuthorized ? "bell.fill" : "bell")
                                        .foregroundColor(.dietCokeRed)
                                        .font(.system(size: 16, weight: .medium))
                                }

                                Text("Notifications")
                                    .fontWeight(.medium)

                                Spacer()

                                if !notificationService.isAuthorized {
                                    Text("Off")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Notifications")
                    }

                    // App Theme Section
                    Section {
                        AppThemePicker()
                    } header: {
                        Text("Appearance")
                    }

                    // Apple Health Section
                    Section {
                        if healthKitManager.isHealthKitAvailable {
                            Button {
                                handleHealthKitToggle()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.red.opacity(0.2), Color.red.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "heart.text.square.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16, weight: .medium))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text("Sync to Apple Health")
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)

                                            // Pro badge if not premium
                                            if !purchaseService.isPremium {
                                                HStack(spacing: 2) {
                                                    Image(systemName: "crown.fill")
                                                        .font(.system(size: 8))
                                                    Text("PRO")
                                                        .font(.system(size: 9, weight: .bold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(
                                                    LinearGradient(
                                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.9, green: 0.7, blue: 0.0)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .clipShape(Capsule())
                                            }
                                        }

                                        Text("Auto-log caffeine intake")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if isRequestingHealthKit {
                                        ProgressView()
                                    } else if purchaseService.isPremium {
                                        Toggle("", isOn: Binding(
                                            get: { healthKitManager.isAutoLogEnabled && healthKitManager.isAuthorized },
                                            set: { _ in handleHealthKitToggle() }
                                        ))
                                        .labelsHidden()
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .disabled(isRequestingHealthKit)
                        } else {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "heart.slash.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16, weight: .medium))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Apple Health")
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)

                                    Text("Not available on this device")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Health")
                    } footer: {
                        if healthKitManager.isHealthKitAvailable && purchaseService.isPremium && healthKitManager.isAuthorized {
                            Text("Caffeine from your drinks will be automatically logged to Apple Health.")
                        }
                    }

                Section {
                    ForEach(BeverageBrand.allCases) { brand in
                        Button {
                            preferences.defaultBrand = brand
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(brand.cardGradient)
                                        .frame(width: 40, height: 40)

                                    BrandIconView(brand: brand, size: DrinkIconSize.sm)
                                        .foregroundStyle(brand.iconGradient)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(brand.rawValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(brand.shortName)
                                        .font(.caption)
                                        .foregroundStyle(brand.iconGradient)
                                }

                                Spacer()

                                if preferences.defaultBrand == brand {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(brand.iconGradient)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Default Beverage")
                } footer: {
                    Text("New drinks will default to this selection. You can still change it when logging each drink.")
                }

                // Data & Privacy Section
                Section {
                    // Export Data
                    Button {
                        exportUserData()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .medium))
                            }

                            Text("Export My Data")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }

                    // Restore Purchases
                    Button {
                        Task {
                            do {
                                try await purchaseService.restorePurchases()
                            } catch {
                                deleteErrorMessage = "Restore failed: \(error.localizedDescription)"
                                showingDeleteError = true
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .medium))
                            }

                            Text("Restore Purchases")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }

                    // Delete Account
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.2), Color.red.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                if isDeletingAccount {
                                    ProgressView()
                                        .tint(.red)
                                } else {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete Account & Data")
                                    .fontWeight(.medium)

                                Text("Permanently delete all your data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isDeletingAccount)
                } header: {
                    Text("Data & Privacy")
                } footer: {
                    Text("Export your data in JSON format. Deleting your account removes all drinks, badges, social connections, and profile data from our servers.")
                }

                #if DEBUG
                Section {
                    // Screenshot Mode - prominent at top
                    Button {
                        populateScreenshotData()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                Image(systemName: "camera.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 16, weight: .medium))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screenshot Mode")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)

                                Text("Populate curated data for App Store screenshots")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(role: .destructive) {
                        clearScreenshotData()
                    } label: {
                        HStack {
                            Image(systemName: "camera.badge.xmark")
                                .foregroundColor(.red)
                            Text("Clear Screenshot Data")
                        }
                    }
                } header: {
                    Text("App Store Screenshots")
                } footer: {
                    Text("Populates realistic data optimized for App Store screenshots: 14-day streak, badges, activity feed, and friends.")
                }

                Section {
                    // Debug User ID Display
                    if let identity = identityService.currentIdentity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your User ID (for debugging)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(identity.userIDString)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.dietCokeRed)
                                    .lineLimit(1)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = identity.userIDString
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }

                            Text("Friend Code: \(identity.friendCode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        populateFakeData()
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("Populate Fake Friends & Feed")
                        }
                    }

                    Button {
                        simulateFriendRequests()
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.clock.fill")
                                .foregroundColor(.orange)
                            Text("Simulate Friend Requests")
                        }
                    }

                    Button {
                        createTestUser()
                    } label: {
                        HStack {
                            if isCreatingTestUser {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.green)
                            Text("Create CloudKit Test User")
                        }
                    }
                    .disabled(isCreatingTestUser)

                    Button(role: .destructive) {
                        clearFakeData()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Fake Data")
                        }
                    }

                    Button {
                        runFriendRequestDiagnostic()
                    } label: {
                        HStack {
                            if isRunningDiagnostic {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Image(systemName: "stethoscope")
                                .foregroundColor(.purple)
                            Text("Diagnose Friend Requests")
                        }
                    }
                    .disabled(isRunningDiagnostic)

                    Button {
                        runActivityDiagnostic()
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.cyan)
                            Text("Diagnose Activity Feed")
                        }
                    }

                    if let result = diagnosticResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }

                    if let code = debugTestUserCode {
                        HStack {
                            Text("Friend Code:")
                            Spacer()
                            Text(code)
                                .fontWeight(.bold)
                                .foregroundColor(.dietCokeRed)
                        }
                    }

                    if let error = debugError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    // Status indicator
                    if friendService.isUsingFakeData {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Fake data active")
                                .foregroundColor(.green)
                            Spacer()
                            Text("\(friendService.friends.count) friends, \(activityService.activities.count) activities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Populate fake friends and activity feed for testing. Data is local only, resets on app restart.")
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            #if DEBUG
            .alert("Screenshot Mode Enabled", isPresented: $showingScreenshotDataAdded) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Added curated data for App Store screenshots:\n• 14-day streak with \(store.entries.count) drinks\n• \(badgeStore.earnedCount) badges unlocked\n• \(activityService.activities.count) activity feed items\n• \(friendService.friends.count) friends")
            }
            .alert("Fake Data Added", isPresented: $showingFakeDataAdded) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Added \(friendService.friends.count) fake friends and \(activityService.activities.count) activity items. Go to Social tab to see them!")
            }
            .alert("Friend Requests Simulated", isPresented: $showingFriendRequestsAdded) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Added \(friendService.pendingRequests.count) fake friend requests. Go to Social → Friends tab to see and accept them!")
            }
            #endif
            .confirmationDialog(
                "Delete Account?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data including drink history, badges, friends, and profile. This action cannot be undone.")
            }
            .alert("Error Deleting Account", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ExportDataSheet(data: data)
                }
            }
            .sheet(isPresented: $showingHealthKitPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Export Data

    private func exportUserData() {
        var exportDict: [String: Any] = [:]

        // User preferences
        exportDict["preferences"] = preferences.exportAllData()

        // Drink entries
        let entriesData = store.entries.map { entry -> [String: Any] in
            var dict: [String: Any] = [
                "id": entry.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: entry.timestamp),
                "type": entry.type.rawValue,
                "brand": entry.brand.rawValue,
                "ounces": entry.ounces
            ]
            if let rating = entry.rating {
                dict["rating"] = rating.rawValue
            }
            return dict
        }
        exportDict["drinkEntries"] = entriesData
        exportDict["totalDrinks"] = store.entries.count
        exportDict["totalOunces"] = store.entries.reduce(0) { $0 + $1.ounces }

        // User identity
        if let identity = identityService.currentIdentity {
            exportDict["userIdentity"] = [
                "friendCode": identity.friendCode,
                "createdAt": ISO8601DateFormatter().string(from: identity.createdAt)
            ]
        }

        // Export date
        exportDict["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportDict["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
            exportData = jsonData
            showingExportSheet = true
        }
    }

    // MARK: - Delete Account

    private func deleteAccount() {
        isDeletingAccount = true

        // Capture references before entering async context
        let preferencesRef = preferences
        let storeRef = store
        let friendServiceRef = friendService
        let activityServiceRef = activityService

        Task {
            do {
                guard let userID = identityService.currentIdentity?.userIDString else {
                    throw NSError(domain: "FridgeCig", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user identity found"])
                }

                // Delete user profile from CloudKit
                try await deleteUserProfile(userID: userID)

                // Delete all drink entries from CloudKit
                try await deleteAllDrinkEntries(userID: userID)

                // Delete all friend connections
                try await deleteAllFriendConnections(userID: userID)

                // Delete all activity items
                try await deleteAllActivityItems(userID: userID)

                // Clear local data
                await MainActor.run {
                    preferencesRef.clearAllData()
                    storeRef.clearAllData()
                    friendServiceRef.clearAllData()
                    activityServiceRef.clearAllData()
                    isDeletingAccount = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    deleteErrorMessage = error.localizedDescription
                    showingDeleteError = true
                    isDeletingAccount = false
                }
            }
        }
    }

    private func deleteUserProfile(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "UserProfile",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1
        )

        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllDrinkEntries(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "DrinkEntry",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1000
        )

        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllFriendConnections(userID: String) async throws {
        // Delete where user is requester
        let requesterRecords = try await cloudKitManager.fetchFromPublic(
            recordType: "FriendConnection",
            predicate: NSPredicate(format: "requesterID == %@", userID),
            limit: 500
        )

        for record in requesterRecords {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }

        // Delete where user is target
        let targetRecords = try await cloudKitManager.fetchFromPublic(
            recordType: "FriendConnection",
            predicate: NSPredicate(format: "targetID == %@", userID),
            limit: 500
        )

        for record in targetRecords {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    private func deleteAllActivityItems(userID: String) async throws {
        let records = try await cloudKitManager.fetchFromPublic(
            recordType: "ActivityItem",
            predicate: NSPredicate(format: "userID == %@", userID),
            limit: 1000
        )

        for record in records {
            try await cloudKitManager.deleteFromPublic(recordID: record.recordID)
        }
    }

    // MARK: - HealthKit Toggle

    private func handleHealthKitToggle() {
        // Check if user is premium
        if !purchaseService.isPremium {
            showingHealthKitPaywall = true
            return
        }

        // If already authorized, toggle auto-log
        if healthKitManager.isAuthorized {
            healthKitManager.isAutoLogEnabled.toggle()
            return
        }

        // Request authorization
        isRequestingHealthKit = true
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    if healthKitManager.isAuthorized {
                        healthKitManager.isAutoLogEnabled = true
                    }
                    isRequestingHealthKit = false
                }
            } catch {
                await MainActor.run {
                    isRequestingHealthKit = false
                }
            }
        }
    }

    #if DEBUG
    private func populateScreenshotData() {
        ScreenshotDataManager.shared.populateScreenshotData(
            drinkStore: store,
            badgeStore: badgeStore,
            activityService: activityService,
            friendService: friendService
        )
        showingScreenshotDataAdded = true
    }

    private func clearScreenshotData() {
        ScreenshotDataManager.shared.clearAllData(
            drinkStore: store,
            badgeStore: badgeStore,
            activityService: activityService,
            friendService: friendService
        )
    }

    private func populateFakeData() {
        friendService.addFakeFriends()
        activityService.addTestActivities()
        showingFakeDataAdded = true
    }

    private func clearFakeData() {
        friendService.clearFakeFriends()
        friendService.clearFakePendingRequests()
        activityService.clearTestActivities()
    }

    private func simulateFriendRequests() {
        guard let userID = identityService.currentIdentity?.userIDString else { return }
        friendService.addFakePendingRequests(targetUserID: userID)
        showingFriendRequestsAdded = true
    }

    private func runActivityDiagnostic() {
        isRunningDiagnostic = true
        diagnosticResult = nil

        Task {
            var result = "Activity Feed Diagnostic\n"
            result += "========================\n\n"

            do {
                // Fetch ALL ActivityItem records (no filter)
                let allRecords = try await cloudKitManager.fetchFromPublic(
                    recordType: "ActivityItem",
                    predicate: NSPredicate(value: true),
                    limit: 20
                )

                result += "Total ActivityItem records in CloudKit: \(allRecords.count)\n\n"

                for record in allRecords {
                    let userID = record["userID"] as? String ?? "nil"
                    let displayName = record["displayName"] as? String ?? "nil"
                    let type = record["type"] as? String ?? "nil"
                    let timestamp = record["timestamp"] as? Date
                    let timeStr = timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "nil"
                    result += "• \(displayName) (\(type)) at \(timeStr)\n"
                    result += "  userID: \(userID.prefix(8))...\n"
                }

                if allRecords.isEmpty {
                    result += "No ActivityItem records found in CloudKit.\n"
                    result += "Activities may not be saving properly."
                }

            } catch {
                result += "ERROR: \(error.localizedDescription)"
            }

            await MainActor.run {
                diagnosticResult = result
                isRunningDiagnostic = false
                AppLogger.general.debug("\(result)")
            }
        }
    }

    private func runFriendRequestDiagnostic() {
        isRunningDiagnostic = true
        diagnosticResult = nil

        Task {
            guard let userID = identityService.currentIdentity?.userIDString else {
                await MainActor.run {
                    diagnosticResult = "ERROR: No identity found"
                    isRunningDiagnostic = false
                }
                return
            }

            var result = "My userID: \(userID)\n"

            do {
                // Fetch ALL pending FriendConnection records (no filter)
                let allPendingRecords = try await cloudKitManager.fetchFromPublic(
                    recordType: "FriendConnection",
                    predicate: NSPredicate(format: "status == %@", "pending"),
                    limit: 50
                )

                result += "Total pending requests in CloudKit: \(allPendingRecords.count)\n\n"

                for record in allPendingRecords {
                    let requesterID = record["requesterID"] as? String ?? "nil"
                    let targetID = record["targetID"] as? String ?? "nil"
                    let status = record["status"] as? String ?? "nil"
                    let isForMe = targetID == userID
                    result += "• req:\(requesterID.prefix(8))... → tgt:\(targetID.prefix(8))... (\(status)) \(isForMe ? "← FOR ME!" : "")\n"
                }

                if allPendingRecords.isEmpty {
                    result += "No pending requests found in CloudKit at all.\n"
                }

                // Now try fetching specifically for this user
                let myPendingRecords = try await cloudKitManager.fetchPendingRequests(forUserID: userID)
                result += "\nPending requests for MY userID: \(myPendingRecords.count)"

            } catch {
                result += "ERROR: \(error.localizedDescription)"
            }

            await MainActor.run {
                diagnosticResult = result
                isRunningDiagnostic = false
                AppLogger.general.debug("\(result)")
            }
        }
    }

    private func createTestUser() {
        isCreatingTestUser = true
        debugError = nil
        debugTestUserCode = nil

        Task {
            do {
                let testID = UUID()
                let friendCode = CloudKitManager.generateFriendCode()

                // Create a fake user profile
                let record = CKRecord(recordType: "UserProfile")
                record["userID"] = testID.uuidString
                record["displayName"] = "Test User \(Int.random(in: 100...999))"
                record["friendCode"] = friendCode
                record["username"] = "testuser\(Int.random(in: 1000...9999))"
                record["isPublic"] = 1
                record["currentStreak"] = Int.random(in: 1...10)
                record["weeklyDrinks"] = Int.random(in: 5...30)
                record["weeklyOunces"] = Double.random(in: 50...300)
                record["monthlyDrinks"] = Int.random(in: 20...100)
                record["monthlyOunces"] = Double.random(in: 200...1000)
                record["allTimeDrinks"] = Int.random(in: 50...500)
                record["allTimeOunces"] = Double.random(in: 500...5000)
                record["statsUpdatedAt"] = Date()
                record["entryCount"] = Int.random(in: 50...500)
                record["averageOuncesPerEntry"] = 12.0
                record["isSuspicious"] = 0
                // Don't set suspiciousFlags - CloudKit doesn't allow empty arrays for new fields

                try await cloudKitManager.saveToPublic(record)

                await MainActor.run {
                    debugTestUserCode = friendCode
                    isCreatingTestUser = false
                }
            } catch {
                await MainActor.run {
                    debugError = error.localizedDescription
                    isCreatingTestUser = false
                }
            }
        }
    }
    #endif
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    let data: Data
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }

                // Info
                VStack(spacing: 8) {
                    Text("Your Data Export")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Your drink history and settings are ready to download in JSON format.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // File info
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text("fridgecig_export.json")
                        .font(.subheadline)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()

                // Share button
                if let url = saveToTemporaryFile() {
                    ShareLink(item: url) {
                        Label("Save Export", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.vertical, 32)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveToTemporaryFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("fridgecig_export.json")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}

#Preview {
    let cloudKitManager = CloudKitManager()
    return SettingsView()
        .environmentObject(UserPreferences())
        .environmentObject(PurchaseService.shared)
        .environmentObject(cloudKitManager)
        .environmentObject(FriendConnectionService(cloudKitManager: cloudKitManager))
        .environmentObject(ActivityFeedService(cloudKitManager: cloudKitManager))
        .environmentObject(NotificationService(cloudKitManager: cloudKitManager))
        .environmentObject(IdentityService(cloudKitManager: cloudKitManager))
        .environmentObject(DrinkStore())
        .environmentObject(ThemeManager())
        .environmentObject(BadgeStore())
}
