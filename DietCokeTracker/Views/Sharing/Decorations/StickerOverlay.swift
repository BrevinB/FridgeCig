import SwiftUI

// MARK: - Sticker Overlay

/// Overlay that renders placed stickers on share cards
struct StickerOverlay: View {
    let stickers: [PlacedSticker]
    let size: CGSize

    var body: some View {
        ForEach(stickers) { placed in
            StickerView(sticker: placed.sticker, size: stickerSize)
                .scaleEffect(placed.scale)
                .rotationEffect(.degrees(placed.rotation))
                .position(placed.position(in: size))
        }
    }

    private var stickerSize: CGFloat {
        // Scale sticker size based on card size
        min(size.width, size.height) * 0.1
    }
}

// MARK: - Interactive Sticker Overlay

/// Sticker overlay with drag, scale, and rotate interactions
struct InteractiveStickerOverlay: View {
    @Binding var stickers: [PlacedSticker]
    let size: CGSize

    @State private var selectedStickerId: UUID?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            ForEach($stickers) { $placed in
                InteractiveStickerItem(
                    placed: $placed,
                    size: size,
                    isSelected: selectedStickerId == placed.id,
                    onSelect: { selectedStickerId = placed.id },
                    onDelete: { deleteSticker(placed) }
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Deselect when tapping background
            selectedStickerId = nil
        }
    }

    private func deleteSticker(_ sticker: PlacedSticker) {
        stickers.removeAll { $0.id == sticker.id }
        selectedStickerId = nil
    }
}

// MARK: - Interactive Sticker Item

struct InteractiveStickerItem: View {
    @Binding var placed: PlacedSticker
    let size: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Double = 0

    private var stickerSize: CGFloat {
        min(size.width, size.height) * 0.1
    }

    var body: some View {
        ZStack {
            StickerView(sticker: placed.sticker, size: stickerSize)
                .scaleEffect(placed.scale * currentScale)
                .rotationEffect(.degrees(placed.rotation + currentRotation))
                .position(placed.position(in: size))
                .gesture(dragGesture)
                .gesture(magnificationGesture)
                .gesture(rotationGesture)
                .onTapGesture {
                    onSelect()
                }

            // Selection indicator
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: stickerSize * placed.scale + 20, height: stickerSize * placed.scale + 20)
                    .position(placed.position(in: size))

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red))
                }
                .position(
                    x: placed.position(in: size).x + stickerSize * placed.scale / 2 + 10,
                    y: placed.position(in: size).y - stickerSize * placed.scale / 2 - 10
                )
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                var updated = placed
                let newPosition = CGPoint(
                    x: placed.position(in: size).x + value.translation.width,
                    y: placed.position(in: size).y + value.translation.height
                )
                updated.setPosition(newPosition, in: size)
                placed = updated
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                currentScale = scale
            }
            .onEnded { scale in
                placed.scale *= scale
                currentScale = 1.0
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                currentRotation = angle.degrees
            }
            .onEnded { angle in
                placed.rotation += angle.degrees
                currentRotation = 0
            }
    }
}

// MARK: - Preview

#if DEBUG
struct StickerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        let stickers = [
            PlacedSticker(
                sticker: StickerLibrary.drinks[0],
                positionX: 0.3,
                positionY: 0.3
            ),
            PlacedSticker(
                sticker: StickerLibrary.celebrations[0],
                positionX: 0.7,
                positionY: 0.5,
                scale: 1.2,
                rotation: 15
            )
        ]

        ZStack {
            Color.blue

            StickerOverlay(
                stickers: stickers,
                size: CGSize(width: 400, height: 600)
            )
        }
        .frame(width: 400, height: 600)
    }
}
#endif
