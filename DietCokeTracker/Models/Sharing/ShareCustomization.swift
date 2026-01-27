import Foundation
import SwiftUI

// MARK: - Share Customization

/// User customizations applied to a share card
struct ShareCustomization: Codable, Equatable {
    /// Selected theme
    var theme: ShareTheme

    /// Selected format (aspect ratio)
    var format: ShareFormat

    /// Custom photo background (photo library asset identifier)
    var photoBackgroundId: String?

    /// Applied stickers with their positions
    var stickers: [PlacedSticker]

    /// Custom accent color override (hex string)
    var customAccentColor: String?

    /// Custom text for the card (if allowed)
    var customText: String?

    /// Whether to show username
    var showUsername: Bool

    /// Whether to show app branding
    var showBranding: Bool

    init(
        theme: ShareTheme = .classic,
        format: ShareFormat = .instagramStory,
        photoBackgroundId: String? = nil,
        stickers: [PlacedSticker] = [],
        customAccentColor: String? = nil,
        customText: String? = nil,
        showUsername: Bool = true,
        showBranding: Bool = true
    ) {
        self.theme = theme
        self.format = format
        self.photoBackgroundId = photoBackgroundId
        self.stickers = stickers
        self.customAccentColor = customAccentColor
        self.customText = customText
        self.showUsername = showUsername
        self.showBranding = showBranding
    }

    // MARK: - Computed Properties

    var hasPhotoBackground: Bool {
        photoBackgroundId != nil
    }

    var hasStickers: Bool {
        !stickers.isEmpty
    }

    var hasCustomizations: Bool {
        hasPhotoBackground || hasStickers || customAccentColor != nil || customText != nil
    }

    /// Check if any premium features are used
    var usesPremiumFeatures: Bool {
        theme.isPremium ||
        format.isPremium ||
        hasPhotoBackground ||
        hasStickers ||
        customAccentColor != nil
    }

    // MARK: - Color Helpers

    var accentColorOverride: Color? {
        guard let hex = customAccentColor else { return nil }
        return Color(hex: hex)
    }

    mutating func setAccentColor(_ color: Color?) {
        customAccentColor = color?.toHex()
    }
}

// MARK: - Placed Sticker

/// A sticker placed on the card with position and transform
struct PlacedSticker: Identifiable, Codable, Equatable {
    let id: UUID
    let sticker: Sticker

    /// Position as percentage of card dimensions (0-1)
    var positionX: CGFloat
    var positionY: CGFloat

    /// Scale factor (1.0 = original size)
    var scale: CGFloat

    /// Rotation in degrees
    var rotation: Double

    init(
        id: UUID = UUID(),
        sticker: Sticker,
        positionX: CGFloat = 0.5,
        positionY: CGFloat = 0.5,
        scale: CGFloat = 1.0,
        rotation: Double = 0
    ) {
        self.id = id
        self.sticker = sticker
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
    }

    /// Convert percentage position to actual points
    func position(in size: CGSize) -> CGPoint {
        CGPoint(
            x: positionX * size.width,
            y: positionY * size.height
        )
    }

    /// Update position from actual points
    mutating func setPosition(_ point: CGPoint, in size: CGSize) {
        positionX = point.x / size.width
        positionY = point.y / size.height
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preset Customizations

extension ShareCustomization {
    /// Default customization for milestones
    static var milestoneDefault: ShareCustomization {
        ShareCustomization(
            theme: .classic,
            format: .instagramStory,
            showUsername: true,
            showBranding: true
        )
    }

    /// Default customization for weekly recaps
    static var recapDefault: ShareCustomization {
        ShareCustomization(
            theme: .classic,
            format: .instagramStory,
            showUsername: false,
            showBranding: true
        )
    }

    /// Minimal style preset
    static var minimalPreset: ShareCustomization {
        ShareCustomization(
            theme: .minimal,
            format: .instagramStory,
            showUsername: false,
            showBranding: false
        )
    }
}
