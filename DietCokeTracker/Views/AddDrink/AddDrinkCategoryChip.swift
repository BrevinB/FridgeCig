import SwiftUI

struct AddDrinkCategoryChip: View {
    let category: DrinkCategory?
    let title: String?
    let sfSymbolIcon: String?
    let isSelected: Bool
    let action: () -> Void

    init(category: DrinkCategory, isSelected: Bool, action: @escaping () -> Void) {
        self.category = category
        self.title = nil
        self.sfSymbolIcon = nil
        self.isSelected = isSelected
        self.action = action
    }

    init(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) {
        self.category = nil
        self.title = title
        self.sfSymbolIcon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    DrinkCategoryIconView(category: category, size: DrinkIconSize.xs)
                        .accessibilityHidden(true)
                } else if let icon = sfSymbolIcon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                Text(category?.rawValue ?? title ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.2))
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .cornerRadius(8)
        }
        .accessibilityLabel("\(category?.rawValue ?? title ?? "") category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: 8) {
        AddDrinkCategoryChip(title: "All", icon: "square.grid.2x2.fill", isSelected: true) {}
        AddDrinkCategoryChip(category: .cans, isSelected: false) {}
        AddDrinkCategoryChip(category: .fountain, isSelected: true) {}
    }
    .padding()
}
