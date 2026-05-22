import SwiftUI

struct DefaultBeverageSection: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
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
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List { DefaultBeverageSection() }
    }
    .withPreviewEnvironment()
}
#endif
