import SwiftUI

/// App-wide theme definitions for Pro users
enum AppTheme: String, CaseIterable, Identifiable {
    case classic   // Free - current red theme
    case midnight  // Pro - dark blue/purple
    case neon      // Pro - pink/purple glow
    case forest    // Pro - green nature
    case sunset    // Pro - orange/pink gradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .midnight: return "Midnight"
        case .neon: return "Neon"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "circle.fill"
        case .midnight: return "moon.stars.fill"
        case .neon: return "sparkles"
        case .forest: return "leaf.fill"
        case .sunset: return "sun.horizon.fill"
        }
    }

    var isPremium: Bool {
        self != .classic
    }

    // MARK: - Primary Colors

    var primaryColor: Color {
        switch self {
        case .classic: return Color.dietCokeRed
        case .midnight: return Color(red: 0.4, green: 0.4, blue: 0.9)
        case .neon: return Color(red: 0.95, green: 0.3, blue: 0.7)
        case .forest: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .sunset: return Color(red: 1.0, green: 0.5, blue: 0.3)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .classic: return Color.dietCokeDeepRed
        case .midnight: return Color(red: 0.25, green: 0.25, blue: 0.6)
        case .neon: return Color(red: 0.6, green: 0.2, blue: 0.8)
        case .forest: return Color(red: 0.15, green: 0.5, blue: 0.3)
        case .sunset: return Color(red: 0.9, green: 0.3, blue: 0.4)
        }
    }

    var accentColor: Color {
        switch self {
        case .classic: return Color.dietCokeRed
        case .midnight: return Color(red: 0.5, green: 0.5, blue: 1.0)
        case .neon: return Color(red: 0.0, green: 1.0, blue: 0.8)
        case .forest: return Color(red: 0.4, green: 0.85, blue: 0.5)
        case .sunset: return Color(red: 1.0, green: 0.7, blue: 0.3)
        }
    }

    // MARK: - Gradients

    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.15), primaryColor.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Background Colors (for dark/light mode)

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .classic:
            return colorScheme == .dark
                ? Color(red: 0.08, green: 0.08, blue: 0.10)
                : Color(red: 0.96, green: 0.96, blue: 0.97)
        case .midnight:
            return colorScheme == .dark
                ? Color(red: 0.05, green: 0.05, blue: 0.12)
                : Color(red: 0.94, green: 0.94, blue: 0.98)
        case .neon:
            return colorScheme == .dark
                ? Color(red: 0.08, green: 0.04, blue: 0.1)
                : Color(red: 0.98, green: 0.95, blue: 0.98)
        case .forest:
            return colorScheme == .dark
                ? Color(red: 0.04, green: 0.08, blue: 0.06)
                : Color(red: 0.95, green: 0.98, blue: 0.96)
        case .sunset:
            return colorScheme == .dark
                ? Color(red: 0.1, green: 0.06, blue: 0.05)
                : Color(red: 0.99, green: 0.97, blue: 0.95)
        }
    }

    func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(white: 0.12)
            : Color.white
    }

    // MARK: - Preview Colors

    var previewColors: [Color] {
        [primaryColor, secondaryColor, accentColor]
    }
}

// MARK: - Theme Preview Swatch

struct ThemePreviewSwatch: View {
    let theme: AppTheme
    let isSelected: Bool
    let isPremium: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Color preview circle
                    Circle()
                        .fill(theme.primaryGradient)
                        .frame(width: 50, height: 50)

                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Lock overlay for non-premium users
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 50, height: 50)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isLocked ? .secondary : .primary)

                if theme.isPremium && !isPremium {
                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}
