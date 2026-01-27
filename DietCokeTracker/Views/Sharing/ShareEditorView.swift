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

                // Theme picker
                HorizontalThemePicker(
                    selectedTheme: $customization.theme,
                    isPremium: isPremium,
                    onPremiumTap: onPremiumTap
                )

                Divider()
                    .padding(.horizontal)

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

    var body: some View {
        NavigationView {
            StickerPicker(
                placedStickers: $placedStickers,
                isPremium: isPremium,
                onPremiumTap: onPremiumTap
            )
            .navigationTitle("Add Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
