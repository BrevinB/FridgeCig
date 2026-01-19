import SwiftUI
import CloudKit

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss

    #if DEBUG
    @State private var debugTestUserCode: String?
    @State private var isCreatingTestUser = false
    @State private var debugError: String?
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
                    Button {
                        createTestUser()
                    } label: {
                        HStack {
                            if isCreatingTestUser {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Create Test User")
                        }
                    }
                    .disabled(isCreatingTestUser)

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
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Creates a fake test user in CloudKit for testing friend features.")
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
        }
    }

    #if DEBUG
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
}
