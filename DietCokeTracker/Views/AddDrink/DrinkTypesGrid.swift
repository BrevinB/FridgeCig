import SwiftUI

struct DrinkTypesGrid: View {
    @Binding var selectedType: DrinkType
    @Binding var selectedCategory: DrinkCategory?

    var filteredTypes: [DrinkType] {
        if let category = selectedCategory {
            return DrinkType.allCases.filter { $0.category == category }
        }
        return DrinkType.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Type")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                AddDrinkCategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }

                ForEach(DrinkCategory.allCases, id: \.self) { category in
                    AddDrinkCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(filteredTypes) { type in
                    DrinkTypeCell(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                            if selectedCategory != type.category {
                                selectedCategory = type.category
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct DrinkTypeCell: View {
    let type: DrinkType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                DrinkIconView(drinkType: type, size: DrinkIconSize.sm)
                    .foregroundColor(isSelected ? .white : .dietCokeRed)
                    .accessibilityHidden(true)

                Text(type.shortName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(type.ounces, format: .number.precision(.fractionLength(0)))oz")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .dietCokeDarkSilver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dietCokeRed : Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityLabel("\(type.displayName), \(type.ounces, format: .number.precision(.fractionLength(0))) ounces")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
private struct DrinkTypesGridPreviewWrapper: View {
    @State private var type: DrinkType = .regularCan
    @State private var category: DrinkCategory? = nil
    var body: some View {
        DrinkTypesGrid(selectedType: $type, selectedCategory: $category)
            .padding()
    }
}

#Preview("Grid") { DrinkTypesGridPreviewWrapper() }

#Preview("Cell — selected") {
    DrinkTypeCell(type: .regularCan, isSelected: true) {}
        .frame(width: 100)
        .padding()
}
#endif
