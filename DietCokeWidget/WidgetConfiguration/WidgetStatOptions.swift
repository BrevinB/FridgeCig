import SwiftUI
import AppIntents

/// Primary stat options for widget display
enum WidgetPrimaryStat: String, CaseIterable, AppEnum {
    case count = "count"
    case ounces = "ounces"
    case streak = "streak"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Primary Stat")
    }

    static var caseDisplayRepresentations: [WidgetPrimaryStat: DisplayRepresentation] {
        [
            .count: DisplayRepresentation(title: "Today's Count"),
            .ounces: DisplayRepresentation(title: "Today's Ounces"),
            .streak: DisplayRepresentation(title: "Current Streak")
        ]
    }

    func getValue(from entry: DietCokeEntry) -> String {
        switch self {
        case .count:
            return "\(entry.todayCount)"
        case .ounces:
            return "\(Int(entry.todayOunces))"
        case .streak:
            return "\(entry.streak)"
        }
    }

    var label: String {
        switch self {
        case .count:
            return "today"
        case .ounces:
            return "oz"
        case .streak:
            return "day streak"
        }
    }

    var icon: String {
        switch self {
        case .count:
            return "cup.and.saucer.fill"
        case .ounces:
            return "drop.fill"
        case .streak:
            return "flame.fill"
        }
    }
}

/// Secondary stat options for widget display
enum WidgetSecondaryStat: String, CaseIterable, AppEnum {
    case none = "none"
    case ounces = "ounces"
    case streak = "streak"
    case weekCount = "weekCount"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Secondary Stat")
    }

    static var caseDisplayRepresentations: [WidgetSecondaryStat: DisplayRepresentation] {
        [
            .none: DisplayRepresentation(title: "None"),
            .ounces: DisplayRepresentation(title: "Today's Ounces"),
            .streak: DisplayRepresentation(title: "Current Streak"),
            .weekCount: DisplayRepresentation(title: "This Week's Count")
        ]
    }

    func getValue(from entry: DietCokeEntry) -> String? {
        switch self {
        case .none:
            return nil
        case .ounces:
            return "\(Int(entry.todayOunces)) oz"
        case .streak:
            return "\(entry.streak) day streak"
        case .weekCount:
            return "\(entry.weekCount) this week"
        }
    }

    var icon: String? {
        switch self {
        case .none:
            return nil
        case .ounces:
            return "drop.fill"
        case .streak:
            return "flame.fill"
        case .weekCount:
            return "calendar"
        }
    }
}

/// Display mode for graph widget
enum GraphDisplayMode: String, CaseIterable, AppEnum {
    case counts = "counts"
    case ounces = "ounces"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Display Mode")
    }

    static var caseDisplayRepresentations: [GraphDisplayMode: DisplayRepresentation] {
        [
            .counts: DisplayRepresentation(title: "Show Counts"),
            .ounces: DisplayRepresentation(title: "Show Ounces")
        ]
    }
}
