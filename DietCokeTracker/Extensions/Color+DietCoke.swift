import SwiftUI

extension Color {
    // MARK: - Diet Coke Brand Colors

    /// Classic Diet Coke red accent
    static let dietCokeRed = Color(red: 0.89, green: 0.09, blue: 0.17)

    /// Diet Coke silver/platinum
    static let dietCokeSilver = Color(red: 0.75, green: 0.75, blue: 0.78)

    /// Diet Coke dark silver
    static let dietCokeDarkSilver = Color(red: 0.45, green: 0.45, blue: 0.48)

    /// Diet Coke charcoal/black
    static let dietCokeCharcoal = Color(red: 0.15, green: 0.15, blue: 0.17)

    /// Light background for cards
    static let dietCokeCardBackground = Color(red: 0.95, green: 0.95, blue: 0.96)

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
    func body(content: Content) -> some View {
        content
            .background(Color.dietCokeCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
