import SwiftUI

struct DrinkCatalogView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: CatalogSection = .drinkTypes
    @State private var selectedDrinkCategory: DrinkCategory?

    enum CatalogSection: String, CaseIterable {
        case drinkTypes = "Drinks"
        case specialEditions = "Special Editions"
        case brands = "Brands"
    }

    private var filteredDrinkTypes: [DrinkType] {
        let types: [DrinkType]
        if let cat = selectedDrinkCategory {
            types = DrinkType.allCases.filter { $0.category == cat }
        } else {
            types = DrinkType.allCases
        }
        if searchText.isEmpty { return types }
        return types.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredEditions: [SpecialEditionCategory: [SpecialEdition]] {
        var result: [SpecialEditionCategory: [SpecialEdition]] = [:]
        for category in SpecialEditionCategory.allCases {
            let editions = SpecialEdition.editions(for: category).filter {
                searchText.isEmpty ||
                $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
                category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
            if !editions.isEmpty {
                result[category] = editions
            }
        }
        return result
    }

    private var filteredBrands: [BeverageBrand] {
        if searchText.isEmpty { return BeverageBrand.allCases }
        return BeverageBrand.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Section picker
                    Picker("Section", selection: $selectedCategory) {
                        ForEach(CatalogSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedCategory {
                    case .drinkTypes:
                        drinkTypesSection
                    case .specialEditions:
                        specialEditionsSection
                    case .brands:
                        brandsSection
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(
                (colorScheme == .dark
                    ? Color(red: 0.08, green: 0.08, blue: 0.10)
                    : Color(red: 0.96, green: 0.96, blue: 0.97))
                    .ignoresSafeArea()
            )
            .navigationTitle("Drink Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search drinks, editions, brands...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Drink Types

    @ViewBuilder
    private var drinkTypesSection: some View {
        VStack(spacing: 12) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    DrinkCategoryChip(title: "All", isSelected: selectedDrinkCategory == nil) {
                        withAnimation { selectedDrinkCategory = nil }
                    }
                    ForEach(DrinkCategory.allCases) { category in
                        DrinkCategoryChip(title: category.rawValue, isSelected: selectedDrinkCategory == category) {
                            withAnimation { selectedDrinkCategory = category }
                        }
                    }
                }
                .padding(.horizontal)
            }

            if filteredDrinkTypes.isEmpty {
                emptyState("No drinks match your search")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredDrinkTypes) { type in
                        DrinkCatalogRow(
                            type: type,
                            brand: preferences.defaultBrand,
                            timesLogged: store.entries.filter { $0.type == type }.count
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Special Editions

    @ViewBuilder
    private var specialEditionsSection: some View {
        let sections = filteredEditions
        let sortedCategories = SpecialEditionCategory.allCases.filter { sections[$0] != nil }

        if sortedCategories.isEmpty {
            emptyState("No special editions match your search")
        } else {
            LazyVStack(spacing: 20) {
                ForEach(sortedCategories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)
                            .padding(.horizontal)

                        ForEach(sections[category] ?? []) { edition in
                            SpecialEditionCatalogRow(
                                edition: edition,
                                timesLogged: store.entries.filter { $0.specialEdition == edition }.count
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Brands

    @ViewBuilder
    private var brandsSection: some View {
        if filteredBrands.isEmpty {
            emptyState("No brands match your search")
        } else {
            LazyVStack(spacing: 10) {
                ForEach(filteredBrands) { brand in
                    BrandCatalogRow(
                        brand: brand,
                        timesLogged: store.entries.filter { $0.brand == brand }.count
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.dietCokeDarkSilver)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Category Chip

private struct DrinkCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.dietCokeRed : Color.dietCokeCardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Drink Type Row

private struct DrinkCatalogRow: View {
    let type: DrinkType
    let brand: BeverageBrand
    let timesLogged: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(brand.lightColor)
                    .frame(width: 52, height: 52)

                DrinkIconView(drinkType: type, size: DrinkIconSize.md)
                    .foregroundColor(brand.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(type.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                HStack(spacing: 8) {
                    Text("\(type.ounces, format: .number.precision(.fractionLength(1)))oz")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)

                    Text("·")
                        .foregroundColor(.dietCokeDarkSilver)

                    Text(type.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            Spacer()

            if timesLogged > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(timesLogged)")
                        .font(.headline)
                        .foregroundColor(brand.color)
                    Text("logged")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Special Edition Row

private struct SpecialEditionCatalogRow: View {
    let edition: SpecialEdition
    let timesLogged: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: edition.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(edition.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                Text(edition.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Spacer()

            if timesLogged > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(timesLogged)")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Text("logged")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            } else {
                Text("Not tried")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.dietCokeSilver.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Brand Row

private struct BrandCatalogRow: View {
    let brand: BeverageBrand
    let timesLogged: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(brand.lightColor)
                    .frame(width: 52, height: 52)

                BrandIconView(brand: brand, size: DrinkIconSize.md)
                    .foregroundColor(brand.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(brand.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                Text(brand.shortName)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            Spacer()

            if timesLogged > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(timesLogged)")
                        .font(.headline)
                        .foregroundColor(brand.color)
                    Text("logged")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    DrinkCatalogView()
        .environmentObject(DrinkStore())
        .environmentObject(UserPreferences())
}
