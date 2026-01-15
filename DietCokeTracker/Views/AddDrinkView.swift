import SwiftUI

struct AddDrinkView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DrinkType = .regularCan
    @State private var note: String = ""
    @State private var selectedCategory: DrinkCategory? = nil
    @State private var selectedSpecialEdition: SpecialEdition? = nil
    @State private var showSpecialEditions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Selected drink preview
                    SelectedDrinkPreview(type: selectedType, specialEdition: selectedSpecialEdition)

                    // Category filter
                    AddDrinkCategoryFilterView(selectedCategory: $selectedCategory)

                    // Drink types grid
                    DrinkTypesGrid(
                        selectedType: $selectedType,
                        selectedCategory: selectedCategory
                    )

                    // Special Edition toggle
                    SpecialEditionSection(
                        showSpecialEditions: $showSpecialEditions,
                        selectedSpecialEdition: $selectedSpecialEdition
                    )

                    // Optional note
                    NoteInputView(note: $note)

                    // Add button
                    Button {
                        store.addDrink(
                            type: selectedType,
                            note: note.isEmpty ? nil : note,
                            specialEdition: selectedSpecialEdition
                        )
                        store.checkBadges(with: badgeStore)
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
    var specialEdition: SpecialEdition? = nil

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(specialEdition != nil ? specialEdition!.toBadge().rarity.color.opacity(0.1) : Color.dietCokeRed.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: specialEdition?.icon ?? type.icon)
                    .font(.system(size: 36))
                    .foregroundColor(specialEdition != nil ? specialEdition!.toBadge().rarity.color : .dietCokeRed)
            }

            VStack(spacing: 4) {
                Text(type.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("\(String(format: "%.1f", type.ounces)) oz")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)

                if let edition = specialEdition {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(edition.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(edition.toBadge().rarity.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(edition.toBadge().rarity.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .dietCokeCard()
    }
}

struct AddDrinkCategoryFilterView: View {
    @Binding var selectedCategory: DrinkCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
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

struct AddDrinkCategoryChip: View {
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

// MARK: - Special Edition Section

struct SpecialEditionSection: View {
    @Binding var showSpecialEditions: Bool
    @Binding var selectedSpecialEdition: SpecialEdition?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSpecialEditions.toggle()
                    if !showSpecialEditions {
                        selectedSpecialEdition = nil
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("Special Edition")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    Spacer()

                    Image(systemName: showSpecialEditions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            if showSpecialEditions {
                VStack(spacing: 8) {
                    Text("Limited releases unlock special badges!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(SpecialEdition.allCases) { edition in
                            SpecialEditionCell(
                                edition: edition,
                                isSelected: selectedSpecialEdition == edition
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedSpecialEdition == edition {
                                        selectedSpecialEdition = nil
                                    } else {
                                        selectedSpecialEdition = edition
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct SpecialEditionCell: View {
    let edition: SpecialEdition
    let isSelected: Bool
    let action: () -> Void

    var badge: Badge {
        edition.toBadge()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: edition.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : badge.rarity.color)

                Text(edition.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? badge.rarity.color : badge.rarity.color.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(badge.rarity.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
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
        .environmentObject(BadgeStore())
}
