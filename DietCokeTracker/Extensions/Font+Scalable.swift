import SwiftUI

/// Extension to make font sizing more accessible with Dynamic Type support
extension Font {
    /// Scalable display font for hero numbers (respects Dynamic Type)
    static func scalableDisplay(_ baseSize: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: baseSize, weight: weight, design: .rounded)
    }

    /// Scalable headline for section headers
    static func scalableHeadline(_ baseSize: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
        .system(size: baseSize, weight: weight, design: .rounded)
    }

    /// Scalable caption for small labels
    static func scalableCaption(_ baseSize: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: baseSize, weight: weight, design: .rounded)
    }
}

/// View modifier for ensuring text scales with Dynamic Type and handles overflow
struct ScalableTextModifier: ViewModifier {
    var minimumScale: CGFloat
    var lineLimit: Int?

    func body(content: Content) -> some View {
        content
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScale)
    }
}

extension View {
    /// Makes text scalable with overflow protection
    func scalableText(minimumScale: CGFloat = 0.75, lineLimit: Int? = nil) -> some View {
        modifier(ScalableTextModifier(minimumScale: minimumScale, lineLimit: lineLimit))
    }
}

/// View modifier for making fixed-height containers more accessible
struct AccessibleFrameModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var baseHeight: CGFloat
    var maxScale: CGFloat

    private var scaledHeight: CGFloat {
        let scale: CGFloat
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            scale = 1.0
        case .large:
            scale = 1.0
        case .extraLarge:
            scale = 1.1
        case .extraExtraLarge:
            scale = 1.2
        case .extraExtraExtraLarge:
            scale = 1.3
        case .accessibilityMedium:
            scale = 1.4
        case .accessibilityLarge:
            scale = 1.5
        case .accessibilityExtraLarge:
            scale = 1.6
        case .accessibilityExtraExtraLarge:
            scale = 1.7
        case .accessibilityExtraExtraExtraLarge:
            scale = 1.8
        @unknown default:
            scale = 1.0
        }
        return baseHeight * min(scale, maxScale)
    }

    func body(content: Content) -> some View {
        content
            .frame(minHeight: scaledHeight)
    }
}

extension View {
    /// Creates a frame with height that scales with Dynamic Type
    func accessibleFrame(baseHeight: CGFloat, maxScale: CGFloat = 1.5) -> some View {
        modifier(AccessibleFrameModifier(baseHeight: baseHeight, maxScale: maxScale))
    }
}
