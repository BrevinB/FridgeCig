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
        case .dietCoke: return "flask.fill"
        case .dietCokeCaffeineFree: return "leaf.fill"
        case .cokeZero: return "bolt.fill"
        case .cokeZeroCaffeineFree: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17) // Red - hero color
        case .dietCokeCaffeineFree: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold for caffeine free
        case .cokeZero: return Color(red: 0.35, green: 0.35, blue: 0.38) // Readable dark gray
        case .cokeZeroCaffeineFree: return Color(red: 0.55, green: 0.35, blue: 0.17) // Bronze for caffeine free
        }
    }

    var lightColor: Color {
        switch self {
        case .dietCoke: return Color(red: 0.89, green: 0.09, blue: 0.17).opacity(0.15)
        case .dietCokeCaffeineFree: return Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15)
        case .cokeZero: return Color(red: 0.35, green: 0.35, blue: 0.38).opacity(0.2)
        case .cokeZeroCaffeineFree: return Color(red: 0.55, green: 0.35, blue: 0.17).opacity(0.15)
        }
    }

    var isCaffeineFree: Bool {
        switch self {
        case .dietCokeCaffeineFree, .cokeZeroCaffeineFree: return true
        case .dietCoke, .cokeZero: return false
        }
    }
}
