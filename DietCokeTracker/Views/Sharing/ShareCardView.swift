import SwiftUI

// MARK: - Share Card View

/// Unified card view for all shareable content types
/// Adapts layout based on format and content type
struct ShareCardView: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    /// Optional background photo (for WeeklyRecap or other content with selected photo)
    var backgroundPhoto: UIImage?

    /// Check if content is a DrinkEntry with photo that should use photo background
    private var entryWithPhotoBackground: (entry: DrinkEntry, photo: UIImage)? {
        guard customization.useEntryPhotoBackground,
              let entry = content as? DrinkEntry,
              let photo = entry.sharePhoto else {
            return nil
        }
        return (entry, photo)
    }

    /// Determine the effective background photo to use
    private var effectiveBackgroundPhoto: UIImage? {
        // For DrinkEntry, use entry's photo
        if let (_, photo) = entryWithPhotoBackground {
            return photo
        }
        // For other content with useEntryPhotoBackground and a provided photo
        if customization.useEntryPhotoBackground, let photo = backgroundPhoto {
            return photo
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // For entries with photos AND useEntryPhotoBackground enabled
                if let (entry, photo) = entryWithPhotoBackground {
                    EntryShareLayout(
                        entry: entry,
                        customization: customization,
                        photo: photo
                    )
                } else if let photo = effectiveBackgroundPhoto {
                    // Photo background for non-entry content (like WeeklyRecap)
                    photoBackgroundLayout(photo: photo, size: geometry.size)
                } else {
                    // Standard layout with theme background
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

    // MARK: - Photo Background Layout (for non-entry content)

    @ViewBuilder
    private func photoBackgroundLayout(photo: UIImage, size: CGSize) -> some View {
        ZStack {
            // Full-bleed photo
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: customization.format.width, height: customization.format.height)
                .clipped()

            // Gradient overlay for readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content on top
            contentLayout(in: size)
                .environment(\.colorScheme, .dark) // Force dark mode for readability on photos
        }
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
