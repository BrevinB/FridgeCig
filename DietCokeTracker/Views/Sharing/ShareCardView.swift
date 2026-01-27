import SwiftUI

// MARK: - Share Card View

/// Unified card view for all shareable content types
/// Adapts layout based on format and content type
struct ShareCardView: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    /// Check if content is a DrinkEntry with photo
    private var entryWithPhoto: (entry: DrinkEntry, photo: UIImage)? {
        guard let entry = content as? DrinkEntry,
              let photo = entry.sharePhoto else {
            return nil
        }
        return (entry, photo)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // For entries with photos, the layout handles its own background
                if let (entry, photo) = entryWithPhoto {
                    EntryShareLayout(
                        entry: entry,
                        customization: customization,
                        photo: photo
                    )
                } else {
                    // Standard layout with background
                    backgroundView

                    // Decorative shapes (behind content)
                    if customization.theme.hasDecorativeShapes {
                        DecorativeShapes(
                            theme: customization.theme,
                            format: customization.format
                        )
                    }

                    // Content layer
                    contentLayout(in: geometry.size)
                }

                // Sticker overlay (on top for all layouts)
                if !customization.stickers.isEmpty {
                    StickerOverlay(
                        stickers: customization.stickers,
                        size: geometry.size
                    )
                }
            }
        }
        .frame(width: customization.format.width, height: customization.format.height)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if customization.hasPhotoBackground {
            PhotoBackground(assetId: customization.photoBackgroundId)
        } else {
            switch customization.theme.backgroundStyle {
            case .solid:
                customization.theme.backgroundColor

            case .gradient:
                GradientBackground(
                    colors: customization.theme.gradientColors,
                    style: .linear
                )

            case .glassmorphic:
                GlassmorphicBackground(theme: customization.theme)

            case .multiGradient:
                GradientBackground(
                    colors: customization.theme.gradientColors,
                    style: .angular
                )
            }
        }
    }

    // MARK: - Content Layout

    @ViewBuilder
    private func contentLayout(in size: CGSize) -> some View {
        // Check if this is a DrinkEntry (without photo - photo entries handled above)
        if let entry = content as? DrinkEntry {
            EntryShareLayout(
                entry: entry,
                customization: customization,
                photo: nil
            )
        } else {
            // Standard layouts for other content types
            switch customization.format.category {
            case .vertical:
                StoryLayout(
                    content: content,
                    customization: customization
                )

            case .square:
                SquareLayout(
                    content: content,
                    customization: customization
                )

            case .horizontal:
                TwitterCardLayout(
                    content: content,
                    customization: customization
                )
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareCardView(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            customization: .milestoneDefault
        )
        .previewLayout(.fixed(width: 1080 * 0.2, height: 1920 * 0.2))
    }
}
#endif
