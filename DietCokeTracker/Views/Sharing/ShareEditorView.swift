import SwiftUI

// MARK: - Share Editor View

/// Full customization editor for share cards
struct ShareEditorView: View {
    let content: any ShareableContent
    @Binding var customization: ShareCustomization
    @Binding var isPresented: Bool

    let isPremium: Bool
    var onShare: () -> Void
    var onPremiumTap: (() -> Void)?

    @State private var showStickerPicker = false

    /// Check if content is a DrinkEntry with a photo available
    private var entryHasPhoto: Bool {
        guard let entry = content as? DrinkEntry else { return false }
        return entry.sharePhoto != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview area
                previewSection

                // Customization controls
                customizationControls
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        onShare()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 8) {
            InteractiveShareCardPreview(
                content: content,
                customization: $customization
            )
            .frame(maxHeight: 320)

            // Hint text when stickers are present
            if !customization.stickers.isEmpty {
                Text("Drag stickers to reposition. Pinch to resize, rotate to spin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Customization Controls

    private var customizationControls: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Format picker
                CompactFormatPicker(
                    selectedFormat: $customization.format,
                    isPremium: isPremium
                )

                Divider()
                    .padding(.horizontal)

                // Background picker (photo vs theme) - only show if entry has photo
                if entryHasPhoto {
                    backgroundPickerSection

                    Divider()
                        .padding(.horizontal)
                }

                // Theme picker - show when not using photo background or for non-photo entries
                if !entryHasPhoto || !customization.useEntryPhotoBackground {
                    HorizontalThemePicker(
                        selectedTheme: $customization.theme,
                        isPremium: isPremium,
                        onPremiumTap: onPremiumTap
                    )

                    Divider()
                        .padding(.horizontal)
                }

                // Stickers section
                stickersSection

                Divider()
                    .padding(.horizontal)

                // Options toggles
                optionsSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Background Picker Section

    private var backgroundPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                // Photo option
                BackgroundOptionButton(
                    title: "Your Photo",
                    icon: "photo.fill",
                    isSelected: customization.useEntryPhotoBackground
                ) {
                    customization.useEntryPhotoBackground = true
                }

                // Theme option
                BackgroundOptionButton(
                    title: "Theme",
                    icon: "paintpalette.fill",
                    isSelected: !customization.useEntryPhotoBackground
                ) {
                    customization.useEntryPhotoBackground = false
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Stickers Section

    private var stickersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stickers")
                    .font(.headline)

                Spacer()

                if !isPremium {
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)

            // Placed stickers with remove option
            if !customization.stickers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tap a sticker in the preview to select it, then drag to move")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    PlacedStickersList(stickers: $customization.stickers)
                }
                .padding(.horizontal)
            }

            // Add sticker button
            Button {
                showStickerPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Sticker")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.dietCokeRed)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerSheet(
                placedStickers: $customization.stickers,
                isPremium: isPremium,
                onPremiumTap: onPremiumTap
            )
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 16) {
            Toggle("Show Username", isOn: $customization.showUsername)
            Toggle("Show App Branding", isOn: $customization.showBranding)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sticker Picker Sheet

struct StickerPickerSheet: View {
    @Binding var placedStickers: [PlacedSticker]
    let isPremium: Bool
    var onPremiumTap: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: StickerCategory = .drinks

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Currently placed stickers
                if !placedStickers.isEmpty {
                    placedStickersHeader
                    Divider()
                }

                // Category tabs
                categoryTabs
                    .padding(.vertical, 12)

                Divider()

                // Stickers grid - scrollable
                ScrollView {
                    stickersGrid
                        .padding(.vertical, 16)
                }
            }
            .navigationTitle("Add Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var placedStickersHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Added Stickers")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(placedStickers) { placed in
                        HStack(spacing: 6) {
                            StickerView(sticker: placed.sticker, size: 32)

                            Button {
                                placedStickers.removeAll { $0.id == placed.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StickerCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.subheadline)
                            Text(category.displayName)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? Color.dietCokeRed : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
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
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(stickers, id: \.id) { sticker in
                StickerGridCell(
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
        let placed = PlacedSticker(
            sticker: sticker,
            positionX: 0.5,
            positionY: 0.5
        )
        placedStickers.append(placed)
    }
}

// MARK: - Sticker Grid Cell (Larger)

struct StickerGridCell: View {
    let sticker: Sticker
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 80)

                VStack(spacing: 6) {
                    if let emoji = sticker.emoji {
                        Text(emoji)
                            .font(.system(size: 36))
                    } else if let symbol = sticker.sfSymbol {
                        Image(systemName: symbol)
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }

                    Text(sticker.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if isLocked {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 80)

                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("Premium")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background Option Button

struct BackgroundOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.dietCokeRed.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .dietCokeRed : .gray)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 2)
                )

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .dietCokeRed : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct ShareEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ShareEditorView(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            customization: .constant(.milestoneDefault),
            isPresented: .constant(true),
            isPremium: false,
            onShare: {}
        )
    }
}
#endif
