import SwiftUI
import AppIntents

/// Accent color options for widget customization
enum WidgetAccentColor: String, CaseIterable, AppEnum {
    case dietCokeRed = "dietCokeRed"
    case cokeZeroBlack = "cokeZeroBlack"
    case oceanBlue = "oceanBlue"
    case mintGreen = "mintGreen"
    case sunsetOrange = "sunsetOrange"
    case lavenderPurple = "lavenderPurple"
    case systemDefault = "systemDefault"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Accent Color")
    }

    static var caseDisplayRepresentations: [WidgetAccentColor: DisplayRepresentation] {
        [
            .dietCokeRed: DisplayRepresentation(title: "DC Red"),
            .cokeZeroBlack: DisplayRepresentation(title: "Coke Zero Black"),
            .oceanBlue: DisplayRepresentation(title: "Ocean Blue"),
            .mintGreen: DisplayRepresentation(title: "Mint Green"),
            .sunsetOrange: DisplayRepresentation(title: "Sunset Orange"),
            .lavenderPurple: DisplayRepresentation(title: "Lavender Purple"),
            .systemDefault: DisplayRepresentation(title: "System Default")
        ]
    }

    var color: Color {
        switch self {
        case .dietCokeRed:
            return .red
        case .cokeZeroBlack:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .oceanBlue:
            return .blue
        case .mintGreen:
            return Color(red: 0.2, green: 0.8, blue: 0.6)
        case .sunsetOrange:
            return .orange
        case .lavenderPurple:
            return Color(red: 0.7, green: 0.5, blue: 0.9)
        case .systemDefault:
            return .primary
        }
    }

    var secondaryColor: Color {
        color.opacity(0.7)
    }

    var backgroundColor: Color {
        color.opacity(0.15)
    }
}

/// Flame color options for streak widgets
enum WidgetFlameColor: String, CaseIterable, AppEnum {
    case orange = "orange"
    case red = "red"
    case blue = "blue"
    case purple = "purple"
    case green = "green"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Flame Color")
    }

    static var caseDisplayRepresentations: [WidgetFlameColor: DisplayRepresentation] {
        [
            .orange: DisplayRepresentation(title: "Classic Orange"),
            .red: DisplayRepresentation(title: "Fire Red"),
            .blue: DisplayRepresentation(title: "Blue Flame"),
            .purple: DisplayRepresentation(title: "Purple Fire"),
            .green: DisplayRepresentation(title: "Green Flame")
        ]
    }

    var color: Color {
        switch self {
        case .orange:
            return .orange
        case .red:
            return .red
        case .blue:
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .purple:
            return .purple
        case .green:
            return Color(red: 0.2, green: 0.9, blue: 0.4)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .orange:
            return [.yellow, .orange, .red]
        case .red:
            return [.orange, .red, Color(red: 0.6, green: 0, blue: 0)]
        case .blue:
            return [.cyan, .blue, Color(red: 0.2, green: 0.2, blue: 0.8)]
        case .purple:
            return [.pink, .purple, Color(red: 0.4, green: 0, blue: 0.6)]
        case .green:
            return [.yellow, .green, Color(red: 0, green: 0.5, blue: 0.3)]
        }
    }
}
