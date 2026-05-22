import SwiftUI

struct BrandSelectorView: View {
    @Binding var selectedBrand: BeverageBrand?
    let defaultBrand: BeverageBrand

    private var effectiveBrand: BeverageBrand {
        selectedBrand ?? defaultBrand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beverage")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            HStack(spacing: 8) {
                ForEach(BeverageBrand.allCases) { brand in
                    BrandButton(
                        brand: brand,
                        isSelected: effectiveBrand == brand,
                        isDefault: defaultBrand == brand && selectedBrand == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedBrand = brand
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct BrandButton: View {
    let brand: BeverageBrand
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AnyShapeStyle(brand.gradient) : AnyShapeStyle(brand.lightColor))
                        .frame(width: 42, height: 42)

                    BrandIconView(brand: brand, size: DrinkIconSize.sm)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(brand.iconGradient))
                }

                Text(brand.shortName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? AnyShapeStyle(brand.iconGradient) : AnyShapeStyle(.secondary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSelected ? brand.lightColor : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? brand.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(brand.rawValue)\(isDefault ? ", default" : "")")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
private struct BrandSelectorPreviewWrapper: View {
    @State private var brand: BeverageBrand? = nil
    var body: some View {
        BrandSelectorView(selectedBrand: $brand, defaultBrand: .dietCoke)
            .padding()
    }
}

#Preview("Selector") {
    BrandSelectorPreviewWrapper()
        .withPreviewEnvironment()
}

#Preview("Single button — selected") {
    BrandButton(brand: .dietCoke, isSelected: true, isDefault: true) {}
        .padding()
}
#endif
