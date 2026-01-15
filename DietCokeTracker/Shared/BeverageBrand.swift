import Foundation
import SwiftUI

enum BeverageBrand: String, Codable, CaseIterable, Identifiable {
    case dietCoke = "Diet Coke"
    case cokeZero = "Coke Zero"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .dietCoke: return "DC"
        case .cokeZero: return "CZ"
        }
    }

    var icon: String {
        switch self {
        case .dietCoke: return "flask.fill"
        case .cokeZero: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17)
        case .cokeZero: return Color(red: 0.1, green: 0.1, blue: 0.1)
        }
    }

    var lightColor: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.15)
        case .cokeZero: return Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.15)
        }
    }
}
