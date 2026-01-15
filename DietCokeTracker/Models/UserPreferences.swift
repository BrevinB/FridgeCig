import Foundation
import SwiftUI
import Combine
@MainActor
class UserPreferences: ObservableObject {
    private let defaultBrandKey = "defaultBeverageBrand"

    @Published var defaultBrand: BeverageBrand {
        didSet {
            saveBrand()
        }
    }

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupID)
    }

    init() {
        // Load saved preference or default to Diet Coke
        if let defaults = UserDefaults(suiteName: SharedDataManager.appGroupID),
           let savedValue = defaults.string(forKey: defaultBrandKey),
           let brand = BeverageBrand(rawValue: savedValue) {
            self.defaultBrand = brand
        } else {
            self.defaultBrand = .dietCoke
        }
    }

    private func saveBrand() {
        sharedDefaults?.set(defaultBrand.rawValue, forKey: defaultBrandKey)
    }
}
