import SwiftUI

struct AddDrinkView: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DrinkType = .regularCan
    @State private var note: String = ""
    @State private var selectedCategory: DrinkCategory? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Selected drink preview
                    SelectedDrinkPreview(type: selectedType)

                    // Category filter
                    CategoryFilterView(selectedCategory: $selectedCategory)

                    // Drink types grid
                    DrinkTypesGrid(
                        selectedType: $selectedType,
                        selectedCategory: selectedCategory
                    )

                    // Optional note
                    NoteInputView(note: $note)

                    // Add button
                    Button {
                        store.addDrink(
                            type: selectedType,
                            note: note.isEmpty ? nil : note
                        )
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Diet Coke")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.dietCokePrimary)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Diet Coke")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dietCokeRed)
                }
            }
        }
    }
}

struct SelectedDrinkPreview: View {
    let type: DrinkType

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: type.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.dietCokeRed)
            }

            VStack(spacing: 4) {
                Text(type.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("\(String(format: "%.1f", type.ounces)) oz")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .dietCokeCard()
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: DrinkCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryChip(
                        title: "All",
                        icon: "square.grid.2x2.fill",
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = nil
                        }
                    }

                    ForEach(DrinkCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.2))
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .cornerRadius(20)
        }
    }
}

struct DrinkTypesGrid: View {
    @Binding var selectedType: DrinkType
    let selectedCategory: DrinkCategory?

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
            ], spacing: 12) {
                ForEach(filteredTypes) { type in
                    DrinkTypeCell(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

struct DrinkTypeCell: View {
    let type: DrinkType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .dietCokeRed)

                Text(type.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
                    .lineLimit(1)

                Text("\(String(format: "%.0f", type.ounces))oz")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .dietCokeDarkSilver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct NoteInputView: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (Optional)")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            TextField("Add a note...", text: $note)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.dietCokeCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    AddDrinkView()
        .environmentObject(DrinkStore())
}
