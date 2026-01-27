import SwiftUI
import CloudKit

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss

    #if DEBUG
    @State private var debugTestUserCode: String?
    @State private var isCreatingTestUser = false
    @State private var debugError: String?
    @State private var showingFakeDataAdded = false
    @State private var showingFriendRequestsAdded = false
    @State private var isRunningDiagnostic = false
    @State private var diagnosticResult: String?
    #endif

    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    NavigationLink {
                        SubscriptionStatusView()
                    } label: {
                        HStack {
                            Image(systemName: purchaseService.isPremium ? "crown.fill" : "crown")
                                .foregroundColor(.dietCokeRed)
                                .font(.title3)
                            Text(purchaseService.isPremium ? "FridgeCig Pro" : "Upgrade to Pro")
                            Spacer()
                            if purchaseService.isPremium {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text("Subscription")
                }

                Section {
                    ForEach(BeverageBrand.allCases) { brand in
                        Button {
                            preferences.defaultBrand = brand
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(brand.lightColor)
                                        .frame(width: 36, height: 36)

                                    Image(systemName: brand.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(brand.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(brand.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(brand.shortName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if preferences.defaultBrand == brand {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(brand.color)
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

                #if DEBUG
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
        }
    }

    #if DEBUG
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
                print("[Diagnostic] \(result)")
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
                print("[Diagnostic] \(result)")
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

#Preview {
    SettingsView()
        .environmentObject(UserPreferences())
        .environmentObject(PurchaseService.shared)
        .environmentObject(CloudKitManager())
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
        .environmentObject(ActivityFeedService(cloudKitManager: CloudKitManager()))
}
