#if DEBUG
import SwiftUI
import CloudKit

struct DebugSection: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var cloudKitManager: CloudKitManager

    @State private var debugTestUserCode: String?
    @State private var isCreatingTestUser = false
    @State private var debugError: String?
    @State private var showingFakeDataAdded = false
    @State private var showingFriendRequestsAdded = false
    @State private var isRunningDiagnostic = false
    @State private var diagnosticResult: String?
    @State private var showingScreenshotDataAdded = false

    var body: some View {
        Group {
            screenshotSection
            debugTools
        }
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
    }

    private var screenshotSection: some View {
        Section {
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
                    Image(systemName: "camera.badge.xmark").foregroundColor(.red)
                    Text("Clear Screenshot Data")
                }
            }
        } header: {
            Text("App Store Screenshots")
        } footer: {
            Text("Populates realistic data optimized for App Store screenshots: 14-day streak, badges, activity feed, and friends.")
        }
    }

    private var debugTools: some View {
        Section {
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
                            Image(systemName: "doc.on.doc").foregroundColor(.blue)
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
                    Image(systemName: "person.3.fill").foregroundColor(.blue)
                    Text("Populate Fake Friends & Feed")
                }
            }

            Button {
                simulateFriendRequests()
            } label: {
                HStack {
                    Image(systemName: "person.badge.clock.fill").foregroundColor(.orange)
                    Text("Simulate Friend Requests")
                }
            }

            Button {
                createTestUser()
            } label: {
                HStack {
                    if isCreatingTestUser {
                        ProgressView().padding(.trailing, 8)
                    }
                    Image(systemName: "person.badge.plus").foregroundColor(.green)
                    Text("Create CloudKit Test User")
                }
            }
            .disabled(isCreatingTestUser)

            Button(role: .destructive) {
                clearFakeData()
            } label: {
                HStack { Image(systemName: "trash"); Text("Clear Fake Data") }
            }

            Button {
                runFriendRequestDiagnostic()
            } label: {
                HStack {
                    if isRunningDiagnostic { ProgressView().padding(.trailing, 8) }
                    Image(systemName: "stethoscope").foregroundColor(.purple)
                    Text("Diagnose Friend Requests")
                }
            }
            .disabled(isRunningDiagnostic)

            Button {
                runActivityDiagnostic()
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle").foregroundColor(.cyan)
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
                    Text(code).fontWeight(.bold).foregroundColor(.dietCokeRed)
                }
            }

            if let error = debugError {
                Text(error).foregroundColor(.red).font(.caption)
            }

            if friendService.isUsingFakeData {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Fake data active").foregroundColor(.green)
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
    }

    // MARK: - Actions

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
            var result = "Activity Feed Diagnostic\n========================\n\n"
            do {
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
                    result += "No ActivityItem records found in CloudKit.\nActivities may not be saving properly."
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
}

#Preview {
    NavigationStack {
        List { DebugSection() }
    }
    .withPreviewEnvironment()
}
#endif
