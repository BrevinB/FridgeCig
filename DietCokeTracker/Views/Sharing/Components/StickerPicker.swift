import SwiftUI

// MARK: - Sticker Picker

/// Picker for selecting and placing stickers on share cards
struct StickerPicker: View {
    @Binding var placedStickers: [PlacedSticker]
    let isPremium: Bool
    var onPremiumTap: (() -> Void)?

    @State private var selectedCategory: StickerCategory = .drinks

    var body: some View {
        VStack(spacing: 16) {
            // Category tabs
            categoryTabs

            // Stickers grid
            stickersGrid
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StickerCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var stickersGrid: some View {
        let stickers = StickerLibrary.stickers(for: selectedCategory)

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(stickers, id: \.id) { sticker in
                StickerCell(
                    sticker: sticker,
                    isLocked: sticker.isPremium && !isPremium
                ) {
                    if sticker.isPremium && !isPremium {
                        onPremiumTap?()
                    } else {
                        addSticker(sticker)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func addSticker(_ sticker: Sticker) {
        // Add sticker at center - user can drag to reposition
        let placed = PlacedSticker(
            sticker: sticker,
            positionX: 0.5,
            positionY: 0.5
        )
        placedStickers.append(placed)
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: StickerCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.dietCokeRed : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sticker Cell

struct StickerCell: View {
    let sticker: Sticker
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                if let emoji = sticker.emoji {
                    Text(emoji)
                        .font(.title2)
                } else if let symbol = sticker.sfSymbol {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundColor(.primary)
                }

                if isLocked {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 50, height: 50)

                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placed Stickers List

/// List of placed stickers with remove option
struct PlacedStickersList: View {
    @Binding var stickers: [PlacedSticker]

    var body: some View {
        if !stickers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Placed Stickers")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stickers) { placed in
                            PlacedStickerChip(sticker: placed) {
                                stickers.removeAll { $0.id == placed.id }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PlacedStickerChip: View {
    let sticker: PlacedSticker
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            StickerView(sticker: sticker.sticker, size: 24)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct StickerPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StickerPicker(
                placedStickers: .constant([]),
                isPremium: false
            )

            PlacedStickersList(
                stickers: .constant([
                    PlacedSticker(sticker: StickerLibrary.drinks[0]),
                    PlacedSticker(sticker: StickerLibrary.celebrations[0])
                ])
            )
        }
        .padding()
    }
}
#endif
