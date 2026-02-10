import SwiftUI

// MARK: - Icon Size Constants

enum DrinkIconSize {
    /// Extra small - for compact chips and tags (14pt)
    static let xs: CGFloat = 14
    /// Small - for list rows and inline elements (18pt)
    static let sm: CGFloat = 18
    /// Medium - for cards and buttons (22pt)
    static let md: CGFloat = 22
    /// Large - for featured content (28pt)
    static let lg: CGFloat = 28
    /// Extra large - for headers and heroes (42pt)
    static let xl: CGFloat = 42
    /// Jumbo - for share images and splash screens (110pt)
    static let jumbo: CGFloat = 110
}

/// A view that renders the appropriate icon for a drink type or special edition.
/// Handles both custom asset icons and SF Symbols.
struct DrinkIconView: View {
    let drinkType: DrinkType
    var specialEdition: SpecialEdition? = nil
    var size: CGFloat = DrinkIconSize.md

    var body: some View {
        if let edition = specialEdition {
            // Special editions always use SF Symbols
            Image(systemName: edition.icon)
                .font(.system(size: size * 0.85))
        } else if drinkType.usesCustomIcon {
            Image(drinkType.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: drinkType.icon)
                .font(.system(size: size * 0.85))
        }
    }
}

/// A view that renders the appropriate icon for a drink category.
/// Handles both custom asset icons and SF Symbols.
struct DrinkCategoryIconView: View {
    let category: DrinkCategory
    var size: CGFloat = DrinkIconSize.md

    var body: some View {
        if category.usesCustomIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: category.icon)
                .font(.system(size: size * 0.85))
        }
    }
}

/// A view that renders the appropriate icon for a beverage brand.
/// Uses custom SVG icons for each brand.
struct BrandIconView: View {
    let brand: BeverageBrand
    var size: CGFloat = DrinkIconSize.md

    var body: some View {
        Image(brand.icon)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            DrinkIconView(drinkType: .regularCan, size: DrinkIconSize.lg)
            DrinkIconView(drinkType: .bottle20oz, size: DrinkIconSize.lg)
            DrinkIconView(drinkType: .fountainMedium, size: DrinkIconSize.lg)
        }

        HStack(spacing: 20) {
            DrinkIconView(drinkType: .mcdonaldsLarge, size: DrinkIconSize.lg)
            DrinkIconView(drinkType: .miniCan, size: DrinkIconSize.lg)
            DrinkIconView(drinkType: .bottle2Liter, size: DrinkIconSize.lg)
        }

        HStack(spacing: 20) {
            DrinkCategoryIconView(category: .cans, size: DrinkIconSize.lg)
            DrinkCategoryIconView(category: .bottles, size: DrinkIconSize.lg)
            DrinkCategoryIconView(category: .fountain, size: DrinkIconSize.lg)
        }
    }
    .foregroundColor(.dietCokeRed)
}
