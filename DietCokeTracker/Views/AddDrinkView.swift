import SwiftUI
import UIKit

struct AddDrinkView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DrinkType = .regularCan
    @State private var selectedBrand: BeverageBrand?
    @State private var note: String = ""
    @State private var selectedCategory: DrinkCategory? = nil
    @State private var selectedSpecialEdition: SpecialEdition? = nil
    @State private var showSpecialEditions = false
    @State private var useCustomOunces = false
    @State private var customOuncesText: String = ""
    @State private var selectedRating: DrinkRating? = nil
    @State private var capturedPhoto: UIImage? = nil
    @State private var showingCamera = false

    // Validation state
    @State private var showingValidationAlert = false
    @State private var validationAlertMessage = ""

    private var effectiveBrand: BeverageBrand {
        selectedBrand ?? preferences.defaultBrand
    }

    private var effectiveOunces: Double {
        if useCustomOunces, let oz = Double(customOuncesText) {
            return oz
        }
        return selectedType.ounces
    }

    private var ouncesValidation: EntryValidator.ValidationResult {
        guard useCustomOunces, let oz = Double(customOuncesText) else {
            return .valid()
        }
        return EntryValidator.validateOunces(oz)
    }

    private var canAddDrink: Bool {
        // Check ounces if custom
        if useCustomOunces {
            guard let oz = Double(customOuncesText), oz > 0 else {
                return false
            }
            if !ouncesValidation.isValid {
                return false
            }
        }

        return true
    }

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 24) {
                        // Selected drink preview
                        SelectedDrinkPreview(
                            type: selectedType,
                            brand: effectiveBrand,
                            specialEdition: selectedSpecialEdition,
                            customOunces: useCustomOunces ? Double(customOuncesText) : nil,
                            rating: selectedRating
                        )

                        // Brand selector
                        BrandSelectorView(
                            selectedBrand: $selectedBrand,
                            defaultBrand: preferences.defaultBrand
                        )

                        // Category filter
                        AddDrinkCategoryFilterView(selectedCategory: $selectedCategory)

                        // Drink types grid
                        DrinkTypesGrid(
                            selectedType: $selectedType,
                            selectedCategory: selectedCategory
                        )

                        // Custom ounces input
                        CustomOuncesSection(
                            useCustomOunces: $useCustomOunces,
                            customOuncesText: $customOuncesText,
                            defaultOunces: selectedType.ounces
                        )

                        // Special Edition toggle
                        SpecialEditionSection(
                            showSpecialEditions: $showSpecialEditions,
                            selectedSpecialEdition: $selectedSpecialEdition
                        )

                        // Rating selector
                        RatingSection(selectedRating: $selectedRating)

                        // Photo section
                        PhotoSection(
                            capturedPhoto: $capturedPhoto,
                            showingCamera: $showingCamera
                        )

                        // Optional note
                        NoteInputView(note: $note)

                        // Add button
                        Button {
                            addDrink()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add \(effectiveBrand.shortName)")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canAddDrink
                                    ? effectiveBrand.buttonGradient
                                    : LinearGradient(
                                        colors: [Color.dietCokeSilver, Color.dietCokeSilver],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(
                                color: canAddDrink ? effectiveBrand.color.opacity(0.3) : Color.clear,
                                radius: 8,
                                y: 4
                            )
                        }
                        .disabled(!canAddDrink)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Add \(effectiveBrand.shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(effectiveBrand.color)
                }
            }
            .alert("Too Fast!", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationAlertMessage)
            }
        }
    }

    private func addDrink() {
        let customOz: Double? = useCustomOunces ? Double(customOuncesText) : nil

        // Full validation
        let validation = store.validateNewEntry(
            type: selectedType,
            customOunces: customOz
        )

        if !validation.isValid {
            validationAlertMessage = validation.errorMessage ?? "Please wait before adding another drink."
            showingValidationAlert = true
            return
        }

        // Validation passed, add the drink
        store.addDrink(
            type: selectedType,
            brand: effectiveBrand,
            note: note.isEmpty ? nil : note,
            specialEdition: selectedSpecialEdition,
            customOunces: customOz,
            rating: selectedRating,
            photo: capturedPhoto
        )
        store.checkBadges(with: badgeStore)
        dismiss()
    }
}

struct SelectedDrinkPreview: View {
    let type: DrinkType
    var brand: BeverageBrand = .dietCoke
    var specialEdition: SpecialEdition? = nil
    var customOunces: Double? = nil
    var rating: DrinkRating? = nil
    @Environment(\.colorScheme) private var colorScheme

    private var displayOunces: Double {
        customOunces ?? type.ounces
    }

    private var accentColor: Color {
        if let edition = specialEdition {
            return edition.toBadge().rarity.color
        }
        return brand.color
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 90, height: 90)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                DrinkIconView(drinkType: type, specialEdition: specialEdition, size: DrinkIconSize.xl)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(type.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                // Brand badge
                HStack(spacing: 4) {
                    BrandIconView(brand: brand, size: DrinkIconSize.xs)
                    Text(brand.shortName)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(brand.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(brand.lightColor)
                )

                HStack(spacing: 4) {
                    Text("\(String(format: "%.1f", displayOunces)) oz")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeDarkSilver)

                    if customOunces != nil {
                        Text("(custom)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeRed)
                    }
                }

                if let edition = specialEdition {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(edition.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(edition.toBadge().rarity.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(edition.toBadge().rarity.color.opacity(0.1))
                    .clipShape(Capsule())
                }

                if let rating = rating {
                    HStack(spacing: 4) {
                        Image(systemName: rating.icon)
                            .font(.caption2)
                        Text(rating.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(rating.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(rating.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: accentColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
            radius: 12,
            y: 4
        )
    }
}

// MARK: - Brand Selector

struct BrandSelectorView: View {
    @Binding var selectedBrand: BeverageBrand?
    let defaultBrand: BeverageBrand

    private var effectiveBrand: BeverageBrand {
        selectedBrand ?? defaultBrand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beverage")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if selectedBrand != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedBrand = nil
                        }
                    } label: {
                        Text("Reset to default")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
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
        .padding(16)
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
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(brand.gradient)
                            .frame(width: 50, height: 50)
                    } else {
                        Circle()
                            .fill(brand.lightColor)
                            .frame(width: 50, height: 50)
                    }

                    BrandIconView(brand: brand, size: DrinkIconSize.md)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(brand.iconGradient))
                }

                Text(brand.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? AnyShapeStyle(brand.iconGradient) : AnyShapeStyle(.secondary))

                if isDefault {
                    Text("default")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                } else {
                    Text(" ")
                        .font(.system(size: 9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? brand.lightColor : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? brand.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(brand.rawValue)\(isDefault ? ", default" : "")")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                            category: category,
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
            HStack(spacing: 6) {
                if let category = category {
                    DrinkCategoryIconView(category: category, size: DrinkIconSize.xs)
                        .accessibilityHidden(true)
                } else if let icon = sfSymbolIcon {
                    Image(systemName: icon)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                Text(category?.rawValue ?? title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.2))
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .cornerRadius(20)
        }
        .accessibilityLabel("\(category?.rawValue ?? title ?? "") category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Special Edition Section

struct SpecialEditionSection: View {
    @Binding var showSpecialEditions: Bool
    @Binding var selectedSpecialEdition: SpecialEdition?
    @State private var showCokeCreations = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSpecialEditions.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("Special Edition")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    Spacer()

                    if let selected = selectedSpecialEdition {
                        Text(selected.rawValue)
                            .font(.caption)
                            .foregroundColor(selected.rarity.color)
                            .lineLimit(1)
                    }

                    Image(systemName: showSpecialEditions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            if showSpecialEditions {
                VStack(spacing: 16) {
                    Text("Limited releases unlock special badges!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Limited Editions
                    SpecialEditionCategorySection(
                        category: .limited,
                        selectedSpecialEdition: $selectedSpecialEdition,
                        isExpanded: .constant(true)
                    )

                    // Diet Coke Flavors
                    SpecialEditionCategorySection(
                        category: .dietCokeFlavors,
                        selectedSpecialEdition: $selectedSpecialEdition,
                        isExpanded: .constant(true)
                    )

                    // Coca-Cola Creations (collapsed by default)
                    SpecialEditionCategorySection(
                        category: .cokeCreations,
                        selectedSpecialEdition: $selectedSpecialEdition,
                        isExpanded: $showCokeCreations,
                        isCollapsible: true
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct SpecialEditionCategorySection: View {
    let category: SpecialEditionCategory
    @Binding var selectedSpecialEdition: SpecialEdition?
    @Binding var isExpanded: Bool
    var isCollapsible: Bool = false

    private var editions: [SpecialEdition] {
        SpecialEdition.editions(for: category)
    }

    private var categoryIcon: String {
        switch category {
        case .limited: return "sparkles"
        case .dietCokeFlavors: return "drop.fill"
        case .cokeCreations: return "wand.and.stars"
        }
    }

    private var hasSelection: Bool {
        editions.contains { $0 == selectedSpecialEdition }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isCollapsible {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: categoryIcon)
                            .font(.caption)
                            .foregroundColor(.dietCokeRed)
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.dietCokeCharcoal)

                        Spacer()

                        if hasSelection, let selected = selectedSpecialEdition {
                            Text(selected.rawValue)
                                .font(.caption2)
                                .foregroundColor(selected.rarity.color)
                                .lineLimit(1)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.caption)
                        .foregroundColor(.dietCokeRed)
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)
                }
            }

            if isExpanded || !isCollapsible {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(editions) { edition in
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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
                    .accessibilityHidden(true)

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
        .accessibilityLabel("\(edition.rawValue) special edition")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                DrinkIconView(drinkType: type, size: DrinkIconSize.md)
                    .foregroundColor(isSelected ? .white : .dietCokeRed)
                    .accessibilityHidden(true)

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
        .accessibilityLabel("\(type.displayName), \(String(format: "%.0f", type.ounces)) ounces")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

// MARK: - Custom Ounces Section

struct CustomOuncesSection: View {
    @Binding var useCustomOunces: Bool
    @Binding var customOuncesText: String
    let defaultOunces: Double

    private var ouncesValidation: EntryValidator.ValidationResult {
        guard let oz = Double(customOuncesText) else {
            return .valid()
        }
        return EntryValidator.validateOunces(oz)
    }

    private var hasError: Bool {
        useCustomOunces && !ouncesValidation.isValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    useCustomOunces.toggle()
                    if useCustomOunces && customOuncesText.isEmpty {
                        customOuncesText = String(format: "%.1f", defaultOunces)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.dietCokeRed)
                    Text("Custom Amount")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    Spacer()

                    Image(systemName: useCustomOunces ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(useCustomOunces ? .dietCokeRed : .dietCokeDarkSilver)
                }
            }

            if useCustomOunces {
                VStack(spacing: 8) {
                    Text("Poured some out? Only had half? Enter the actual amount.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Limits reminder
                    Text("Min: \(Int(EntryValidator.minOuncesPerEntry)) oz • Max: \(Int(EntryValidator.maxOuncesPerEntry)) oz")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        TextField("Amount", text: $customOuncesText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(hasError ? Color.red : Color.dietCokeRed.opacity(0.3), lineWidth: hasError ? 2 : 1)
                            )

                        Text("oz")
                            .font(.headline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    // Error message
                    if hasError, let message = ouncesValidation.errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(message)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Quick adjust buttons
                    HStack(spacing: 8) {
                        QuickOzButton(label: "1/4", multiplier: 0.25, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "1/2", multiplier: 0.5, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "3/4", multiplier: 0.75, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "Full", multiplier: 1.0, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
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

struct QuickOzButton: View {
    let label: String
    let multiplier: Double
    let defaultOunces: Double
    @Binding var customOuncesText: String

    private var resultingOunces: Double {
        defaultOunces * multiplier
    }

    var body: some View {
        Button {
            customOuncesText = String(format: "%.1f", resultingOunces)
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.dietCokeSilver.opacity(0.2))
                .foregroundColor(.dietCokeCharcoal)
                .cornerRadius(8)
        }
        .accessibilityLabel("\(label) of default, \(String(format: "%.1f", resultingOunces)) ounces")
    }
}

// MARK: - Rating Section

struct RatingSection: View {
    @Binding var selectedRating: DrinkRating?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Rate this DC")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if selectedRating != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRating = nil
                        }
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            Text("How was it? (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(DrinkRating.allCases) { rating in
                    RatingButton(
                        rating: rating,
                        isSelected: selectedRating == rating
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedRating == rating {
                                selectedRating = nil
                            } else {
                                selectedRating = rating
                            }
                        }
                    }
                }
            }

            if let rating = selectedRating {
                Text(rating.description)
                    .font(.caption)
                    .foregroundColor(rating.color)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct RatingButton: View {
    let rating: DrinkRating
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: rating.icon)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(rating.displayName)
                    .font(.system(size: 9))
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? rating.color : rating.color.opacity(0.1))
            .foregroundColor(isSelected ? .white : rating.color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate as \(rating.displayName)")
        .accessibilityHint(rating.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Photo Section

struct PhotoSection: View {
    @Binding var capturedPhoto: UIImage?
    @Binding var showingCamera: Bool

    @StateObject private var verificationService = ImageVerificationService()
    @State private var pendingPhoto: UIImage?
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Photo")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if capturedPhoto != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            capturedPhoto = nil
                        }
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            Text("Take a photo of your drink (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let photo = capturedPhoto {
                // Photo preview
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Button {
                            if CameraView.isAvailable {
                                showingCamera = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .accessibilityHidden(true)
                                Text("Retake")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        }
                        .accessibilityLabel("Retake photo")
                        .padding(8),
                        alignment: .bottomTrailing
                    )
            } else {
                // Camera button
                Button {
                    if CameraView.isAvailable {
                        showingCamera = true
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .accessibilityHidden(true)
                        Text(CameraView.isAvailable ? "Take Photo" : "Camera Unavailable")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CameraView.isAvailable ? .dietCokeRed : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!CameraView.isAvailable)
                .accessibilityLabel(CameraView.isAvailable ? "Take photo of your drink" : "Camera unavailable")
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $pendingPhoto)
        }
        .onChange(of: pendingPhoto) { _, newPhoto in
            guard let photo = newPhoto else { return }
            verifyPhoto(photo)
        }
        .alert("Not a Diet Coke?", isPresented: $showingVerificationAlert) {
            Button("Use Anyway", role: .destructive) {
                if let photo = pendingPhoto {
                    capturedPhoto = photo
                }
                pendingPhoto = nil
            }
            Button("Retake", role: .cancel) {
                pendingPhoto = nil
                showingCamera = true
            }
        } message: {
            Text(verificationMessage)
        }
        .overlay {
            if verificationService.isVerifying {
                ZStack {
                    Color.black.opacity(0.3)
                        .cornerRadius(12)
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Verifying photo...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func verifyPhoto(_ photo: UIImage) {
        // Only verify on iOS 26+ with Apple Intelligence
        guard ImageVerificationService.isAvailable else {
            // No verification available, just accept the photo
            capturedPhoto = photo
            pendingPhoto = nil
            return
        }

        Task {
            let result = await verificationService.verifyImage(photo)

            if result.isValid {
                capturedPhoto = photo
                pendingPhoto = nil
            } else {
                verificationMessage = result.message
                showingVerificationAlert = true
            }
        }
    }
}

#Preview {
    AddDrinkView()
        .environmentObject(DrinkStore())
        .environmentObject(BadgeStore())
}
