import Foundation
import SwiftUI

enum DrinkType: String, CaseIterable, Codable, Identifiable {
    case regularCan = "Regular Can"
    case tallCan = "Tall Can"
    case miniCan = "Mini Can"
    case bottle20oz = "20oz Bottle"
    case bottle2Liter = "2 Liter"
    case mcdonaldsSmall = "McDonald's Small"
    case mcdonaldsMedium = "McDonald's Medium"
    case mcdonaldsLarge = "McDonald's Large"
    case chickfilaSmall = "Chick-fil-A Small"
    case chickfilaMedium = "Chick-fil-A Medium"
    case chickfilaLarge = "Chick-fil-A Large"
    case fountainSmall = "Fountain Small"
    case fountainMedium = "Fountain Medium"
    case fountainLarge = "Fountain Large"
    case glassBottle = "Glass Bottle"
    case glassWithIce = "Glass with Ice"
    case cafeFreestyle = "Freestyle Machine"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .regularCan, .tallCan:
            return "can"
        case .miniCan:
            return "mini-can"
        case .bottle20oz:
            return "bottle"
        case .bottle2Liter:
            return "two-liter"
        case .glassBottle:
            return "bottle"
        case .glassWithIce:
            return "glass-ice"
        case .mcdonaldsSmall, .mcdonaldsMedium, .mcdonaldsLarge:
            return "m.circle.fill"
        case .chickfilaSmall, .chickfilaMedium, .chickfilaLarge:
            return "c.circle.fill"
        case .fountainSmall, .fountainMedium, .fountainLarge:
            return "fountain-cup"
        case .cafeFreestyle:
            return "drop.circle.fill"
        }
    }

    var usesCustomIcon: Bool {
        switch self {
        case .mcdonaldsSmall, .mcdonaldsMedium, .mcdonaldsLarge,
             .chickfilaSmall, .chickfilaMedium, .chickfilaLarge,
             .cafeFreestyle:
            return false
        case .regularCan, .tallCan, .miniCan, .bottle20oz, .bottle2Liter,
             .glassBottle, .glassWithIce, .fountainSmall, .fountainMedium, .fountainLarge:
            return true
        }
    }

    @ViewBuilder
    var iconImage: some View {
        if usesCustomIcon {
            Image(icon)
                .renderingMode(.template)
        } else {
            Image(systemName: icon)
        }
    }

    var ounces: Double {
        switch self {
        case .miniCan:
            return 7.5
        case .regularCan, .glassBottle, .glassWithIce:
            return 12
        case .tallCan:
            return 16
        case .bottle20oz:
            return 20
        case .bottle2Liter:
            return 67.6
        case .mcdonaldsSmall, .chickfilaSmall, .fountainSmall:
            return 16
        case .mcdonaldsMedium, .chickfilaMedium, .fountainMedium:
            return 21
        case .mcdonaldsLarge, .chickfilaLarge, .fountainLarge:
            return 30
        case .cafeFreestyle:
            return 20
        }
    }

    var category: DrinkCategory {
        switch self {
        case .regularCan, .tallCan, .miniCan:
            return .cans
        case .bottle20oz, .bottle2Liter, .glassBottle:
            return .bottles
        case .mcdonaldsSmall, .mcdonaldsMedium, .mcdonaldsLarge:
            return .mcdonalds
        case .chickfilaSmall, .chickfilaMedium, .chickfilaLarge:
            return .chickfila
        case .fountainSmall, .fountainMedium, .fountainLarge, .cafeFreestyle, .glassWithIce:
            return .fountain
        }
    }

    var displayName: String {
        return rawValue
    }

    var shortName: String {
        switch self {
        case .regularCan: return "Can"
        case .tallCan: return "Tall"
        case .miniCan: return "Mini"
        case .bottle20oz: return "20oz"
        case .bottle2Liter: return "2L"
        case .mcdonaldsSmall: return "McD S"
        case .mcdonaldsMedium: return "McD M"
        case .mcdonaldsLarge: return "McD L"
        case .chickfilaSmall: return "CFA S"
        case .chickfilaMedium: return "CFA M"
        case .chickfilaLarge: return "CFA L"
        case .fountainSmall: return "Ftn S"
        case .fountainMedium: return "Ftn M"
        case .fountainLarge: return "Ftn L"
        case .glassBottle: return "Glass Btl"
        case .glassWithIce: return "Glass"
        case .cafeFreestyle: return "Freestyle"
        }
    }
}

enum DrinkCategory: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    case cans = "Cans"
    case bottles = "Bottles"
    case mcdonalds = "McDonald's"
    case chickfila = "Chick-fil-A"
    case fountain = "Fountain"

    var types: [DrinkType] {
        DrinkType.allCases.filter { $0.category == self }
    }

    var icon: String {
        switch self {
        case .cans: return "can"
        case .bottles: return "bottle"
        case .mcdonalds: return "m.circle.fill"
        case .chickfila: return "c.circle.fill"
        case .fountain: return "fountain-cup"
        }
    }

    var usesCustomIcon: Bool {
        switch self {
        case .mcdonalds, .chickfila:
            return false
        default:
            return true
        }
    }

    @ViewBuilder
    var iconImage: some View {
        if usesCustomIcon {
            Image(icon)
                .renderingMode(.template)
        } else {
            Image(systemName: icon)
        }
    }
}
