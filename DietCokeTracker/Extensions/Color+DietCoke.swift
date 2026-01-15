import SwiftUI
import UIKit

extension Color {
    // MARK: - Diet Coke Brand Colors (Dark Mode Adaptive)

    /// Classic Diet Coke red accent (same in both modes)
    static let dietCokeRed = Color(red: 0.89, green: 0.09, blue: 0.17)

    /// Diet Coke silver/platinum - adapts to dark mode
    static let dietCokeSilver = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.65, green: 0.65, blue: 0.68, alpha: 1)
            : UIColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1)
    })

    /// Diet Coke dark silver - adapts to dark mode
    static let dietCokeDarkSilver = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1)
            : UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
    })

    /// Diet Coke charcoal/text color - inverts for dark mode
    static let dietCokeCharcoal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1)
            : UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1)
    })

    /// Background for cards - adapts to dark mode
    static let dietCokeCardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
    })

    /// Gradient for backgrounds
    static let dietCokeGradient = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.85, blue: 0.88),
            Color(red: 0.95, green: 0.95, blue: 0.97)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark gradient for headers
    static let dietCokeDarkGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.15, blue: 0.17),
            Color(red: 0.25, green: 0.25, blue: 0.28)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Accent gradient with red
    static let dietCokeAccentGradient = LinearGradient(
        colors: [
            Color(red: 0.89, green: 0.09, blue: 0.17),
            Color(red: 0.75, green: 0.08, blue: 0.15)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - View Modifiers

struct DietCokeCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.dietCokeCardBackground)
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: colorScheme == .dark ? 4 : 8,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
    }
}

struct DietCokePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                    ? Color.dietCokeRed.opacity(0.8)
                    : Color.dietCokeRed
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DietCokeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.dietCokeCharcoal)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                    ? Color.dietCokeSilver.opacity(0.6)
                    : Color.dietCokeSilver.opacity(0.3)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dietCokeSilver, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func dietCokeCard() -> some View {
        modifier(DietCokeCardStyle())
    }
}

extension ButtonStyle where Self == DietCokePrimaryButtonStyle {
    static var dietCokePrimary: DietCokePrimaryButtonStyle {
        DietCokePrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == DietCokeSecondaryButtonStyle {
    static var dietCokeSecondary: DietCokeSecondaryButtonStyle {
        DietCokeSecondaryButtonStyle()
    }
}
