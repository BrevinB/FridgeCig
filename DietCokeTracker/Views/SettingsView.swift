import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

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
}

#Preview {
    SettingsView()
        .environmentObject(UserPreferences())
        .environmentObject(PurchaseService.shared)
}
