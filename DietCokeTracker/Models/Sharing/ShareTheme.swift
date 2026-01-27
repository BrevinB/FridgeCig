import Foundation
import SwiftUI

// MARK: - Share Theme

/// Unified theme system for all shareable content types
enum ShareTheme: String, CaseIterable, Identifiable, Codable {
    // Free themes
    case classic       // Diet Coke Red
    case minimal       // Clean white

    // Premium themes
    case midnight      // Dark blue-purple
    case neon          // Pink/purple glow
    case retro         // Vintage cream
    case glassDark     // Glassmorphism dark
    case glassLight    // Glassmorphism light
    case gradient90s   // Multi-color retro
    case brutalist     // Bold typography
    case pastel        // Soft gradients

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        case .midnight: return "Midnight"
        case .neon: return "Neon"
        case .retro: return "Retro"
        case .glassDark: return "Glass Dark"
        case .glassLight: return "Glass Light"
        case .gradient90s: return "90s Gradient"
        case .brutalist: return "Brutalist"
        case .pastel: return "Pastel"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "paintbrush.fill"
        case .minimal: return "square.fill"
        case .midnight: return "moon.stars.fill"
        case .neon: return "sparkles"
        case .retro: return "clock.arrow.circlepath"
        case .glassDark: return "rectangle.fill.on.rectangle.fill"
        case .glassLight: return "rectangle.on.rectangle"
        case .gradient90s: return "rainbow"
        case .brutalist: return "bold"
        case .pastel: return "drop.fill"
        }
    }

    var isPremium: Bool {
        switch self {
        case .classic, .minimal:
            return false
        default:
            return true
        }
    }

    // MARK: - Colors

    var backgroundColor: Color {
        switch self {
        case .classic:
            return Color.dietCokeRed
        case .minimal:
            return .white
        case .midnight:
            return Color(red: 0.08, green: 0.08, blue: 0.14)
        case .neon:
            return Color(red: 0.08, green: 0.04, blue: 0.16)
        case .retro:
            return Color(red: 0.96, green: 0.92, blue: 0.86)
        case .glassDark:
            return Color(red: 0.1, green: 0.1, blue: 0.12)
        case .glassLight:
            return Color(red: 0.95, green: 0.95, blue: 0.97)
        case .gradient90s:
            return Color(red: 0.15, green: 0.1, blue: 0.25)
        case .brutalist:
            return Color(red: 1.0, green: 0.98, blue: 0.9)
        case .pastel:
            return Color(red: 0.95, green: 0.92, blue: 0.98)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .classic, .midnight, .neon, .glassDark, .gradient90s:
            return .white
        case .minimal, .retro, .glassLight, .brutalist, .pastel:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .classic:
            return .white.opacity(0.85)
        case .minimal:
            return Color(white: 0.45)
        case .midnight:
            return Color(red: 0.6, green: 0.65, blue: 0.8)
        case .neon:
            return Color(red: 0.85, green: 0.6, blue: 1.0)
        case .retro:
            return Color(red: 0.5, green: 0.42, blue: 0.35)
        case .glassDark:
            return Color(white: 0.7)
        case .glassLight:
            return Color(white: 0.4)
        case .gradient90s:
            return Color(red: 0.9, green: 0.85, blue: 1.0)
        case .brutalist:
            return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .pastel:
            return Color(red: 0.5, green: 0.45, blue: 0.55)
        }
    }

    var accentColor: Color {
        switch self {
        case .classic:
            return .white
        case .minimal:
            return Color.dietCokeRed
        case .midnight:
            return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .neon:
            return Color(red: 1.0, green: 0.3, blue: 0.7)
        case .retro:
            return Color(red: 0.85, green: 0.45, blue: 0.25)
        case .glassDark:
            return Color(red: 0.5, green: 0.7, blue: 1.0)
        case .glassLight:
            return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .gradient90s:
            return Color(red: 1.0, green: 0.6, blue: 0.3)
        case .brutalist:
            return Color(red: 1.0, green: 0.2, blue: 0.2)
        case .pastel:
            return Color(red: 0.7, green: 0.5, blue: 0.8)
        }
    }

    /// Background color for content cards (semi-transparent overlay)
    var cardBackgroundColor: Color {
        switch self {
        case .classic:
            return Color.white.opacity(0.15)
        case .minimal:
            return Color.white
        case .midnight:
            return Color(red: 0.12, green: 0.12, blue: 0.2).opacity(0.8)
        case .neon:
            return Color(red: 0.15, green: 0.08, blue: 0.25).opacity(0.85)
        case .retro:
            return Color(red: 1.0, green: 0.98, blue: 0.94).opacity(0.9)
        case .glassDark:
            return Color(red: 0.15, green: 0.15, blue: 0.2).opacity(0.6)
        case .glassLight:
            return Color.white.opacity(0.7)
        case .gradient90s:
            return Color(red: 0.1, green: 0.08, blue: 0.18).opacity(0.8)
        case .brutalist:
            return Color.white
        case .pastel:
            return Color.white.opacity(0.85)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .classic:
            return [Color.dietCokeRed, Color.dietCokeRed.opacity(0.85)]
        case .minimal:
            return [.white, Color(white: 0.97)]
        case .midnight:
            return [
                Color(red: 0.12, green: 0.12, blue: 0.22),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]
        case .neon:
            return [
                Color(red: 0.25, green: 0.08, blue: 0.4),
                Color(red: 0.08, green: 0.04, blue: 0.2)
            ]
        case .retro:
            return [
                Color(red: 0.96, green: 0.92, blue: 0.86),
                Color(red: 0.92, green: 0.88, blue: 0.82)
            ]
        case .glassDark:
            return [
                Color(red: 0.15, green: 0.15, blue: 0.2),
                Color(red: 0.08, green: 0.08, blue: 0.12)
            ]
        case .glassLight:
            return [
                Color(red: 0.98, green: 0.98, blue: 1.0),
                Color(red: 0.92, green: 0.92, blue: 0.96)
            ]
        case .gradient90s:
            return [
                Color(red: 0.4, green: 0.2, blue: 0.6),
                Color(red: 0.2, green: 0.4, blue: 0.5),
                Color(red: 0.9, green: 0.5, blue: 0.3)
            ]
        case .brutalist:
            return [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.98, green: 0.96, blue: 0.88)
            ]
        case .pastel:
            return [
                Color(red: 0.95, green: 0.88, blue: 0.98),
                Color(red: 0.88, green: 0.92, blue: 0.98),
                Color(red: 0.92, green: 0.98, blue: 0.92)
            ]
        }
    }

    // MARK: - Background Style

    var backgroundStyle: BackgroundStyle {
        switch self {
        case .classic, .minimal, .midnight, .neon, .retro, .brutalist:
            return .gradient
        case .glassDark, .glassLight:
            return .glassmorphic
        case .gradient90s, .pastel:
            return .multiGradient
        }
    }

    enum BackgroundStyle {
        case solid
        case gradient
        case glassmorphic
        case multiGradient
    }

    // MARK: - Typography

    var titleFont: Font {
        switch self {
        case .brutalist:
            return .system(size: 72, weight: .black, design: .default)
        case .retro:
            return .system(size: 56, weight: .bold, design: .serif)
        case .minimal:
            return .system(size: 52, weight: .light, design: .default)
        default:
            return .system(size: 56, weight: .bold, design: .rounded)
        }
    }

    var bodyFont: Font {
        switch self {
        case .brutalist:
            return .system(size: 24, weight: .bold, design: .monospaced)
        case .retro:
            return .system(size: 22, weight: .medium, design: .serif)
        case .minimal:
            return .system(size: 22, weight: .regular, design: .default)
        default:
            return .system(size: 22, weight: .medium, design: .rounded)
        }
    }

    // MARK: - Decorative Elements

    var hasDecorativeShapes: Bool {
        switch self {
        case .neon, .gradient90s, .pastel:
            return true
        default:
            return false
        }
    }

    var decorativeShapeOpacity: Double {
        switch self {
        case .neon: return 0.3
        case .gradient90s: return 0.4
        case .pastel: return 0.25
        default: return 0
        }
    }
}

// MARK: - Theme Categories

extension ShareTheme {
    /// Free themes available to all users
    static var freeThemes: [ShareTheme] {
        allCases.filter { !$0.isPremium }
    }

    /// Premium themes requiring subscription
    static var premiumThemes: [ShareTheme] {
        allCases.filter { $0.isPremium }
    }
}
