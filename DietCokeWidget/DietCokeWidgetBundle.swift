//
//  DietCokeWidgetBundle.swift
//  DietCokeWidget
//
//  Created by Brevin Blalock on 1/14/26.
//

import WidgetKit
import SwiftUI

@main
struct DietCokeWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Standard widgets
        DietCokeWidget()
        QuickAddWidget()

        // New configurable widget
        ConfigurableDietCokeWidget()

        // New specialized widgets
        GraphWidget()
        StreakWidget()

        // Lock screen widgets
        StreakLockScreenWidget()
        MinimalLockScreenWidget()
    }
}
