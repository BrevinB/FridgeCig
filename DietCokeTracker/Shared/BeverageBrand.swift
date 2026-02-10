import Foundation
import SwiftUI

enum BeverageBrand: String, Codable, CaseIterable, Identifiable {
    case dietCoke = "Diet Coke"
    case dietCokeCaffeineFree = "Diet Coke Caffeine Free"
    case cokeZero = "Coke Zero"
    case cokeZeroCaffeineFree = "Coke Zero Caffeine Free"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .dietCoke: return "DC"
        case .dietCokeCaffeineFree: return "DCCF"
        case .cokeZero: return "CZ"
        case .cokeZeroCaffeineFree: return "CZCF"
        }
    }

    var icon: String {
        switch self {
        case .dietCoke: return "diet-coke"
        case .dietCokeCaffeineFree: return "diet-coke-caffeine-free"
        case .cokeZero: return "coke-zero"
        case .cokeZeroCaffeineFree: return "coke-zero-caffeine-free"
        }
    }

    /// All beverage brands now use custom icons
    var usesCustomIcon: Bool { true }

    // MARK: - Primary Colors

    /// Primary brand color - used for main accents
    var color: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17) // DC Red
        case .dietCokeCaffeineFree: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
        case .cokeZero: return Color(red: 0.89, green: 0.09, blue: 0.17) // CZ Red (same red as DC)
        case .cokeZeroCaffeineFree: return Color(red: 0.55, green: 0.35, blue: 0.17) // Bronze
        }
    }

    /// Secondary brand color - used for gradients and accents
    var secondaryColor: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17) // Same red
        case .dietCokeCaffeineFree: return Color(red: 0.95, green: 0.85, blue: 0.55) // Light gold
        case .cokeZero: return Color(red: 0.08, green: 0.08, blue: 0.10) // Black
        case .cokeZeroCaffeineFree: return Color(red: 0.35, green: 0.22, blue: 0.12) // Dark bronze
        }
    }

    /// Light background tint
    var lightColor: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.15)
        case .dietCokeCaffeineFree: return Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15)
        case .cokeZero: return Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.12)
        case .cokeZeroCaffeineFree: return Color(red: 0.55, green: 0.35, blue: 0.17).opacity(0.15)
        }
    }

    // MARK: - Gradients

    /// Icon gradient - for SF Symbols
    var iconGradient: LinearGradient {
        switch self {
        case .dietCoke:
            // Solid red
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.89, green: 0.09, blue: 0.17)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .dietCokeCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.65, blue: 0.13),
                    Color(red: 0.95, green: 0.85, blue: 0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cokeZero:
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.15, green: 0.15, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cokeZeroCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 0.17),
                    Color(red: 0.35, green: 0.22, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Primary gradient - main brand gradient
    var gradient: LinearGradient {
        switch self {
        case .dietCoke:
            // Solid red
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.89, green: 0.09, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dietCokeCaffeineFree:
            // Gold gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.65, blue: 0.13),
                    Color(red: 0.95, green: 0.85, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cokeZero:
            // Red to Black
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cokeZeroCaffeineFree:
            // Bronze gradient
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 0.17),
                    Color(red: 0.35, green: 0.22, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Button gradient - more subtle, for interactive elements
    var buttonGradient: LinearGradient {
        switch self {
        case .dietCoke:
            // Solid red
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.89, green: 0.09, blue: 0.17)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .dietCokeCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.65, blue: 0.13),
                    Color(red: 0.75, green: 0.55, blue: 0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .cokeZero:
            // Red with black accent
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17),
                    Color(red: 0.55, green: 0.06, blue: 0.10),
                    Color(red: 0.15, green: 0.15, blue: 0.17)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .cokeZeroCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 0.17),
                    Color(red: 0.45, green: 0.28, blue: 0.14)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// Card background gradient - subtle brand tint
    var cardGradient: LinearGradient {
        switch self {
        case .dietCoke:
            // Solid red tint
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.10),
                    Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dietCokeCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.08),
                    Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cokeZero:
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cokeZeroCaffeineFree:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 0.17).opacity(0.08),
                    Color(red: 0.35, green: 0.22, blue: 0.12).opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var isCaffeineFree: Bool {
        switch self {
        case .dietCokeCaffeineFree, .cokeZeroCaffeineFree: return true
        case .dietCoke, .cokeZero: return false
        }
    }
}
