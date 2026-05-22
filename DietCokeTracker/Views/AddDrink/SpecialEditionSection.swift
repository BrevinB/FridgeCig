import SwiftUI

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

                    SpecialEditionCategorySection(
                        category: .limited,
                        selectedSpecialEdition: $selectedSpecialEdition,
                        isExpanded: .constant(true)
                    )

                    SpecialEditionCategorySection(
                        category: .dietCokeFlavors,
                        selectedSpecialEdition: $selectedSpecialEdition,
                        isExpanded: .constant(true)
                    )

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

#if DEBUG
private struct SpecialEditionPreviewWrapper: View {
    @State private var showExpanded: Bool
    @State private var selected: SpecialEdition?

    init(expanded: Bool = true, selected: SpecialEdition? = nil) {
        _showExpanded = State(initialValue: expanded)
        _selected = State(initialValue: selected)
    }

    var body: some View {
        SpecialEditionSection(
            showSpecialEditions: $showExpanded,
            selectedSpecialEdition: $selected
        )
        .padding()
    }
}

#Preview("Expanded") { SpecialEditionPreviewWrapper(expanded: true) }
#Preview("Collapsed") { SpecialEditionPreviewWrapper(expanded: false) }
#Preview("With selection") {
    SpecialEditionPreviewWrapper(expanded: true, selected: .america250)
}
#endif
