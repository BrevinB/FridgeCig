import Foundation
import SwiftUI

enum DrinkRating: Int, Codable, CaseIterable, Identifiable {
    case flat = 1
    case meh = 2
    case decent = 3
    case crisp = 4
    case transcendent = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .flat: return "Flat"
        case .meh: return "Meh"
        case .decent: return "Decent"
        case .crisp: return "Crisp"
        case .transcendent: return "Transcendent"
        }
    }

    var description: String {
        switch self {
        case .flat: return "Stale, lost its fizz"
        case .meh: return "Below average"
        case .decent: return "Solid, gets the job done"
        case .crisp: return "Great refreshment"
        case .transcendent: return "Perfect Diet Coke moment"
        }
    }

    var icon: String {
        switch self {
        case .flat: return "cloud.rain"
        case .meh: return "hand.thumbsdown"
        case .decent: return "hand.thumbsup"
        case .crisp: return "sparkles"
        case .transcendent: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .flat: return .gray
        case .meh: return .orange
        case .decent: return .blue
        case .crisp: return .green
        case .transcendent: return .yellow
        }
    }
}
