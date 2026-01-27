import SwiftUI

// MARK: - Share Card Preview Container

/// A properly scaled preview container for ShareCardView
/// Handles the scaling math to display the full-size card in a small preview
struct ShareCardPreviewContainer: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    // The actual card size (1080x1920 for story format)
    private var cardWidth: CGFloat { customization.format.width }
    private var cardHeight: CGFloat { customization.format.height }
    private var aspectRatio: CGFloat { cardWidth / cardHeight }

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width

            // Calculate scale to fit within the available space
            let scaleToFitHeight = availableHeight / cardHeight
            let scaleToFitWidth = availableWidth / cardWidth
            let scale = min(scaleToFitHeight, scaleToFitWidth)

            // Scaled dimensions
            let scaledWidth = cardWidth * scale
            let scaledHeight = cardHeight * scale

            ZStack {
                // Background for the preview area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))

                // The actual card, scaled down
                ShareCardView(content: content, customization: customization)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(Rectangle()) // Clip at full size first
                    .scaleEffect(scale)
                    .frame(width: scaledWidth, height: scaledHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Small corner radius after scaling
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Interactive Share Card Preview

/// An interactive preview that allows dragging, scaling, and rotating stickers
struct InteractiveShareCardPreview: View {
    let content: any ShareableContent
    @Binding var customization: ShareCustomization

    // The actual card size
    private var cardWidth: CGFloat { customization.format.width }
    private var cardHeight: CGFloat { customization.format.height }

    @State private var selectedStickerId: UUID?

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width

            // Calculate scale to fit within the available space
            let scaleToFitHeight = availableHeight / cardHeight
            let scaleToFitWidth = availableWidth / cardWidth
            let scale = min(scaleToFitHeight, scaleToFitWidth)

            // Scaled dimensions
            let scaledWidth = cardWidth * scale
            let scaledHeight = cardHeight * scale

            ZStack {
                // Background for the preview area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))

                // Card preview (without stickers - we'll overlay them)
                cardPreviewWithoutStickers(scale: scale, scaledWidth: scaledWidth, scaledHeight: scaledHeight)

                // Interactive sticker overlay (at scaled size)
                interactiveStickerLayer(scaledWidth: scaledWidth, scaledHeight: scaledHeight)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    @ViewBuilder
    private func cardPreviewWithoutStickers(scale: CGFloat, scaledWidth: CGFloat, scaledHeight: CGFloat) -> some View {
        // Create a customization without stickers for the base card
        let baseCustomization = ShareCustomization(
            theme: customization.theme,
            format: customization.format,
            photoBackgroundId: customization.photoBackgroundId,
            stickers: [], // No stickers - we overlay them interactively
            customAccentColor: customization.customAccentColor,
            customText: customization.customText,
            showUsername: customization.showUsername,
            showBranding: customization.showBranding
        )

        ShareCardView(content: content, customization: baseCustomization)
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(Rectangle())
            .scaleEffect(scale)
            .frame(width: scaledWidth, height: scaledHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    @ViewBuilder
    private func interactiveStickerLayer(scaledWidth: CGFloat, scaledHeight: CGFloat) -> some View {
        ZStack {
            // Tap to deselect
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedStickerId = nil
                }

            // Draggable stickers
            ForEach($customization.stickers) { $sticker in
                DraggableStickerView(
                    sticker: $sticker,
                    containerSize: CGSize(width: scaledWidth, height: scaledHeight),
                    isSelected: selectedStickerId == sticker.id,
                    onSelect: { selectedStickerId = sticker.id },
                    onDelete: {
                        customization.stickers.removeAll { $0.id == sticker.id }
                        selectedStickerId = nil
                    }
                )
            }
        }
        .frame(width: scaledWidth, height: scaledHeight)
    }
}

// MARK: - Draggable Sticker View

struct DraggableStickerView: View {
    @Binding var sticker: PlacedSticker
    let containerSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero

    // Sticker size scales with container
    private var stickerSize: CGFloat {
        min(containerSize.width, containerSize.height) * 0.12
    }

    private var currentPosition: CGPoint {
        CGPoint(
            x: sticker.positionX * containerSize.width + dragOffset.width,
            y: sticker.positionY * containerSize.height + dragOffset.height
        )
    }

    var body: some View {
        ZStack {
            // Sticker
            stickerContent
                .position(currentPosition)
                .gesture(dragGesture)
                .simultaneousGesture(scaleGesture)
                .simultaneousGesture(rotationGesture)
                .onTapGesture {
                    onSelect()
                }

            // Selection UI
            if isSelected {
                selectionOverlay
            }
        }
    }

    private var stickerContent: some View {
        StickerView(sticker: sticker.sticker, size: stickerSize)
            .scaleEffect(sticker.scale * gestureScale)
            .rotationEffect(.degrees(sticker.rotation) + gestureRotation)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }

    private var selectionOverlay: some View {
        ZStack {
            // Selection ring
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .shadow(color: .black.opacity(0.3), radius: 2)
                .frame(
                    width: stickerSize * sticker.scale + 24,
                    height: stickerSize * sticker.scale + 24
                )
                .position(currentPosition)

            // Delete button
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .position(
                x: currentPosition.x + (stickerSize * sticker.scale / 2) + 8,
                y: currentPosition.y - (stickerSize * sticker.scale / 2) - 8
            )
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                // Update the sticker position
                let newX = sticker.positionX + (value.translation.width / containerSize.width)
                let newY = sticker.positionY + (value.translation.height / containerSize.height)

                // Clamp to keep sticker within bounds
                sticker.positionX = max(0.05, min(0.95, newX))
                sticker.positionY = max(0.05, min(0.95, newY))
                dragOffset = .zero
            }
    }

    private var scaleGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                sticker.scale = max(0.5, min(3.0, sticker.scale * value))
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                state = value
            }
            .onEnded { value in
                sticker.rotation += value.degrees
            }
    }
}

// MARK: - Preview

#if DEBUG
struct ShareCardPreviewContainer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ShareCardPreviewContainer(
                content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
                customization: .milestoneDefault
            )
            .frame(height: 280)

            ShareCardPreviewContainer(
                content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
                customization: ShareCustomization(theme: .classic, format: .instagramPost)
            )
            .frame(height: 200)
        }
        .padding()
    }
}
#endif
