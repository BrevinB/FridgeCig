import Foundation
import SwiftUI

// MARK: - Badge Model

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let type: BadgeType
    let title: String
    let description: String
    let icon: String
    let rarity: BadgeRarity
    var unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var formattedUnlockDate: String? {
        guard let date = unlockedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Returns the description with {drink} placeholder replaced by the brand's short name
    func description(for brand: BeverageBrand) -> String {
        description
            .replacingOccurrences(of: "{drink}", with: brand.shortName)
            .replacingOccurrences(of: "{drinks}", with: "\(brand.shortName)s")
    }
}

// MARK: - Badge Type

enum BadgeType: String, Codable, Equatable {
    case milestone
    case streak
    case special
    case variety
    case volume
    case lifestyle  // Funny time/behavior based badges
}

// MARK: - Badge Rarity

enum BadgeRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Special Edition

enum SpecialEditionCategory: String, CaseIterable {
    case limited = "Limited Editions"
    case dietCokeFlavors = "DC Flavors"
    case cokeCreations = "Coca-Cola Creations"
}

enum SpecialEdition: String, Codable, CaseIterable, Identifiable {
    // Limited Editions
    case fifa2026 = "FIFA World Cup 2026"
    case summerVibes = "Summer Vibes 2025"
    case holidaySeason = "Holiday Season"
    case retroEdition = "Retro Edition"

    // DC Flavors
    case zeroSugarLime = "Zero Sugar Lime"
    case cherryVanilla = "Cherry Vanilla"
    case gingerLime = "Ginger Lime"
    case feistyCherry = "Feisty Cherry"
    case twistedMango = "Twisted Mango"
    case zestyBloodOrange = "Zesty Blood Orange"
    case strawberryGuava = "Strawberry Guava"
    case blueberryAcai = "Blueberry Acai"
    case dietCherry = "Diet Cherry"
    case cherryFloat = "Cherry Float"
    case retroLime = "Retro Lime"

    // Coca-Cola Creations
    case starlight = "Starlight"
    case dreamworld = "Dreamworld"
    case marshmello = "Marshmello"
    case byte = "Byte"
    case move = "Move"
    case ultimate = "Ultimate"
    case y3000 = "Y3000"
    case kWave = "K-Wave"
    case happyTears = "Happy Tears"
    case oreo = "Oreo"

    var id: String { rawValue }

    var category: SpecialEditionCategory {
        switch self {
        case .fifa2026, .summerVibes, .holidaySeason, .retroEdition:
            return .limited
        case .zeroSugarLime, .cherryVanilla, .gingerLime, .feistyCherry,
             .twistedMango, .zestyBloodOrange, .strawberryGuava, .blueberryAcai,
             .dietCherry, .cherryFloat, .retroLime:
            return .dietCokeFlavors
        case .starlight, .dreamworld, .marshmello, .byte, .move,
             .ultimate, .y3000, .kWave, .happyTears, .oreo:
            return .cokeCreations
        }
    }

    static func editions(for category: SpecialEditionCategory) -> [SpecialEdition] {
        allCases.filter { $0.category == category }
    }

    var icon: String {
        switch self {
        case .fifa2026: return "soccerball"
        case .summerVibes: return "sun.max.fill"
        case .holidaySeason: return "gift.fill"
        case .retroEdition: return "clock.arrow.circlepath"
        case .zeroSugarLime: return "leaf.fill"
        case .cherryVanilla: return "heart.fill"
        case .gingerLime: return "leaf.circle.fill"
        case .feistyCherry: return "flame.fill"
        case .twistedMango: return "tropicalstorm"
        case .zestyBloodOrange: return "circle.hexagongrid.fill"
        case .strawberryGuava: return "heart.circle.fill"
        case .blueberryAcai: return "circle.grid.cross.fill"
        case .dietCherry: return "apple.meditate"
        case .cherryFloat: return "mug.fill"
        case .retroLime: return "clock.badge.checkmark.fill"
        case .starlight: return "star.fill"
        case .dreamworld: return "moon.stars.fill"
        case .marshmello: return "music.note"
        case .byte: return "gamecontroller.fill"
        case .move: return "figure.dance"
        case .ultimate: return "bolt.shield.fill"
        case .y3000: return "cpu.fill"
        case .kWave: return "waveform.circle.fill"
        case .happyTears: return "face.smiling.fill"
        case .oreo: return "circle.circle.fill"
        }
    }

    var badgeDescription: String {
        switch self {
        case .fifa2026:
            return "Enjoyed a FIFA World Cup 2026 limited edition"
        case .summerVibes:
            return "Tried the Summer Vibes limited release"
        case .holidaySeason:
            return "Celebrated with a Holiday Season edition"
        case .retroEdition:
            return "Sipped on a classic Retro Edition"
        case .zeroSugarLime:
            return "Tasted the Zero Sugar Lime variant"
        case .cherryVanilla:
            return "Enjoyed the Cherry Vanilla flavor"
        case .gingerLime:
            return "Sipped the botanical Ginger Lime"
        case .feistyCherry:
            return "Tried the bold Feisty Cherry"
        case .twistedMango:
            return "Enjoyed the tropical Twisted Mango"
        case .zestyBloodOrange:
            return "Tasted the tangy Zesty Blood Orange"
        case .strawberryGuava:
            return "Tried the fruity Strawberry Guava"
        case .blueberryAcai:
            return "Enjoyed the exotic Blueberry Acai"
        case .dietCherry:
            return "Classic Diet Cherry - back permanently"
        case .cherryFloat:
            return "Enjoyed the creamy Cherry Float"
        case .retroLime:
            return "Sipped the vintage Retro Lime"
        case .starlight:
            return "Experienced the cosmic Starlight edition"
        case .dreamworld:
            return "Explored the Dreamworld limited flavor"
        case .marshmello:
            return "Vibed with the Marshmello collaboration"
        case .byte:
            return "Tasted pixels with the gaming-inspired Byte"
        case .move:
            return "Danced with the Rosalía collab Move"
        case .ultimate:
            return "Leveled up with the League of Legends Ultimate"
        case .y3000:
            return "Tried the AI co-created Y3000 from the future"
        case .kWave:
            return "Felt the K-Pop magic with K-Wave"
        case .happyTears:
            return "Tasted happy tears with peach and minerals"
        case .oreo:
            return "Enjoyed the cookie-inspired Oreo collab"
        }
    }

    var rarity: BadgeRarity {
        switch self {
        case .fifa2026, .starlight, .dreamworld, .marshmello, .y3000, .ultimate:
            return .legendary
        case .summerVibes, .holidaySeason, .byte, .move, .kWave, .happyTears, .oreo:
            return .epic
        case .retroEdition, .cherryFloat, .retroLime:
            return .rare
        case .zeroSugarLime, .cherryVanilla, .gingerLime, .feistyCherry,
             .twistedMango, .zestyBloodOrange, .strawberryGuava, .blueberryAcai, .dietCherry:
            return .uncommon
        }
    }

    func toBadge() -> Badge {
        Badge(
            id: "special_\(self.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))",
            type: .special,
            title: rawValue,
            description: badgeDescription,
            icon: icon,
            rarity: rarity,
            unlockedAt: nil
        )
    }
}

// MARK: - All Available Badges

struct BadgeDefinitions {

    // MARK: - Milestone Badges (Count Based)

    static let milestones: [Badge] = [
        Badge(id: "first_sip", type: .milestone, title: "First Sip",
              description: "Log your first {drink}", icon: "flask.fill", rarity: .common),
        Badge(id: "getting_started", type: .milestone, title: "Getting Started",
              description: "Log 10 {drinks}", icon: "flame.fill", rarity: .common),
        Badge(id: "regular", type: .milestone, title: "Regular",
              description: "Log 25 {drinks}", icon: "star.fill", rarity: .uncommon),
        Badge(id: "enthusiast", type: .milestone, title: "Enthusiast",
              description: "Log 50 {drinks}", icon: "star.circle.fill", rarity: .uncommon),
        Badge(id: "dedicated", type: .milestone, title: "Dedicated",
              description: "Log 100 {drinks}", icon: "medal.fill", rarity: .rare),
        Badge(id: "centurion", type: .milestone, title: "Centurion",
              description: "Log 250 {drinks}", icon: "crown.fill", rarity: .rare),
        Badge(id: "legend", type: .milestone, title: "Legend",
              description: "Log 500 {drinks}", icon: "trophy.fill", rarity: .epic),
        Badge(id: "ultimate", type: .milestone, title: "Ultimate Fan",
              description: "Log 1000 {drinks}", icon: "sparkles", rarity: .legendary),
    ]

    static func milestoneThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "first_sip": return 1
        case "getting_started": return 10
        case "regular": return 25
        case "enthusiast": return 50
        case "dedicated": return 100
        case "centurion": return 250
        case "legend": return 500
        case "ultimate": return 1000
        default: return nil
        }
    }

    // MARK: - Streak Badges

    static let streaks: [Badge] = [
        Badge(id: "streak_3", type: .streak, title: "Three-peat",
              description: "Maintain a 3-day streak", icon: "3.circle.fill", rarity: .common),
        Badge(id: "streak_7", type: .streak, title: "Week Warrior",
              description: "Maintain a 7-day streak", icon: "7.circle.fill", rarity: .uncommon),
        Badge(id: "streak_14", type: .streak, title: "Fortnight Fighter",
              description: "Maintain a 14-day streak", icon: "calendar", rarity: .rare),
        Badge(id: "streak_30", type: .streak, title: "Monthly Master",
              description: "Maintain a 30-day streak", icon: "calendar.badge.checkmark", rarity: .epic),
        Badge(id: "streak_100", type: .streak, title: "Century Streak",
              description: "Maintain a 100-day streak", icon: "bolt.shield.fill", rarity: .legendary),
    ]

    static func streakThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "streak_3": return 3
        case "streak_7": return 7
        case "streak_14": return 14
        case "streak_30": return 30
        case "streak_100": return 100
        default: return nil
        }
    }

    // MARK: - Volume Badges (Ounces Based)

    static let volume: [Badge] = [
        Badge(id: "volume_100", type: .volume, title: "First Gallon",
              description: "Drink 128+ ounces total", icon: "drop.circle.fill", rarity: .common),
        Badge(id: "volume_500", type: .volume, title: "Half Grand",
              description: "Drink 500+ ounces total", icon: "scalemass.fill", rarity: .uncommon),
        Badge(id: "volume_1000", type: .volume, title: "Kiloounce Club",
              description: "Drink 1000+ ounces total", icon: "waterbottle.fill", rarity: .rare),
        Badge(id: "volume_5000", type: .volume, title: "Ocean Sipper",
              description: "Drink 5000+ ounces total", icon: "water.waves", rarity: .epic),
        Badge(id: "volume_10000", type: .volume, title: "Hydration Hero",
              description: "Drink 10000+ ounces total", icon: "hurricane", rarity: .legendary),
    ]

    static func volumeThreshold(for badgeId: String) -> Double? {
        switch badgeId {
        case "volume_100": return 128
        case "volume_500": return 500
        case "volume_1000": return 1000
        case "volume_5000": return 5000
        case "volume_10000": return 10000
        default: return nil
        }
    }

    // MARK: - Variety Badges

    static let variety: [Badge] = [
        Badge(id: "variety_3", type: .variety, title: "Variety Seeker",
              description: "Try 3 different drink types", icon: "square.grid.2x2.fill", rarity: .common),
        Badge(id: "variety_5", type: .variety, title: "Explorer",
              description: "Try 5 different drink types", icon: "map.fill", rarity: .uncommon),
        Badge(id: "variety_10", type: .variety, title: "Adventurer",
              description: "Try 10 different drink types", icon: "safari.fill", rarity: .rare),
        Badge(id: "variety_all", type: .variety, title: "Completionist",
              description: "Try all drink types", icon: "checkmark.seal.fill", rarity: .epic),
    ]

    static func varietyThreshold(for badgeId: String) -> Int? {
        switch badgeId {
        case "variety_3": return 3
        case "variety_5": return 5
        case "variety_10": return 10
        case "variety_all": return DrinkType.allCases.count
        default: return nil
        }
    }

    // MARK: - Special Edition Badges

    static var specialEditions: [Badge] {
        SpecialEdition.allCases.map { $0.toBadge() }
    }

    // MARK: - Lifestyle Badges (Funny/Shareable)

    static let lifestyle: [Badge] = [
        // Time-based
        Badge(id: "early_bird", type: .lifestyle, title: "Early Bird",
              description: "Log a {drink} before 6am. The real ones know.", icon: "sunrise.fill", rarity: .uncommon),
        Badge(id: "night_owl", type: .lifestyle, title: "Night Owl",
              description: "Log a {drink} after midnight. Sleep is overrated.", icon: "moon.stars.fill", rarity: .uncommon),
        Badge(id: "lunch_break", type: .lifestyle, title: "Lunch Break Essential",
              description: "Log a {drink} between 11am-1pm. The perfect midday pick-me-up.", icon: "fork.knife", rarity: .common),
        Badge(id: "happy_hour", type: .lifestyle, title: "Happy Hour",
              description: "Log a {drink} between 4-6pm. Who needs alcohol?", icon: "party.popper.fill", rarity: .common),

        // Frequency-based (same day)
        Badge(id: "double_fisting", type: .lifestyle, title: "Double Fisting",
              description: "Log 2 {drinks} within an hour. Hydration is key.", icon: "hand.raised.fingers.spread.fill", rarity: .uncommon),
        Badge(id: "triple_threat", type: .lifestyle, title: "Triple Threat",
              description: "Log 3 {drinks} in a single day. Caffeine? Never heard of too much.", icon: "3.square.fill", rarity: .rare),
        Badge(id: "dc_bender", type: .lifestyle, title: "Bender",
              description: "Log 5+ {drinks} in a single day. Are you okay? (We support you)", icon: "figure.roll", rarity: .epic),
        Badge(id: "absolute_unit", type: .lifestyle, title: "Absolute Unit",
              description: "Log 7+ {drinks} in a single day. You're built different.", icon: "bolt.trianglebadge.exclamationmark.fill", rarity: .legendary),

        // Weekend/Day-based
        Badge(id: "weekend_warrior", type: .lifestyle, title: "Weekend Warrior",
              description: "Log a {drink} on both Saturday and Sunday. No days off.", icon: "calendar.badge.clock", rarity: .common),
        Badge(id: "monday_motivation", type: .lifestyle, title: "Monday Motivation",
              description: "Log a {drink} on a Monday. The only way to survive.", icon: "m.circle.fill", rarity: .common),
        Badge(id: "friday_feeling", type: .lifestyle, title: "Friday Feeling",
              description: "Log a {drink} on a Friday. Weekend starts now.", icon: "f.circle.fill", rarity: .common),

        // Funny milestones
        Badge(id: "no_judgement", type: .lifestyle, title: "No Judgement Zone",
              description: "Log a {drink} before 8am AND after 10pm same day. We don't judge.", icon: "eyes", rarity: .rare),
        Badge(id: "creature_of_habit", type: .lifestyle, title: "Creature of Habit",
              description: "Log a {drink} at the same hour 3 days in a row. Routine is everything.", icon: "repeat.circle.fill", rarity: .rare),
        Badge(id: "speedrunner", type: .lifestyle, title: "Speedrunner",
              description: "Log a {drink} within 5 minutes of waking up (before 7am). Priorities.", icon: "hare.fill", rarity: .uncommon),

        // Social/situational
        Badge(id: "sharing_is_caring", type: .lifestyle, title: "Sharing is Caring",
              description: "Except {drinks}. Those are mine. (Log 10 {drinks})", icon: "person.2.slash.fill", rarity: .common),
        Badge(id: "main_character", type: .lifestyle, title: "Main Character Energy",
              description: "Log a {drink} every single day for 2 weeks. This is your story.", icon: "sparkle.magnifyingglass", rarity: .epic),
        Badge(id: "its_not_an_addiction", type: .lifestyle, title: "It's Not an Addiction",
              description: "Log 50 {drinks} total. I can stop whenever I want.", icon: "hand.raised.fill", rarity: .uncommon),
        Badge(id: "send_help", type: .lifestyle, title: "Send Help",
              description: "Log 200 {drinks} total. Just kidding, send more {drink}.", icon: "megaphone.fill", rarity: .rare),
        Badge(id: "professional", type: .lifestyle, title: "Professional Drinker",
              description: "Log 500 {drinks} total. Put it on your resume.", icon: "briefcase.fill", rarity: .epic),
        Badge(id: "dc_deity", type: .lifestyle, title: "Deity",
              description: "Log 1000 {drinks}. You have ascended.", icon: "crown.fill", rarity: .legendary),

        // Container-based
        Badge(id: "can_collector", type: .lifestyle, title: "Can Collector",
              description: "Log 20 cans. Time to start a sculpture.", icon: "shippingbox.fill", rarity: .uncommon),
        Badge(id: "fountain_of_youth", type: .lifestyle, title: "Fountain of Youth",
              description: "Log 10 fountain drinks. Gas station gourmet.", icon: "drop.circle.fill", rarity: .uncommon),
        Badge(id: "big_gulp_energy", type: .lifestyle, title: "Big Gulp Energy",
              description: "Log 5 large fountain drinks. Go big or go home.", icon: "arrow.up.circle.fill", rarity: .rare),
        Badge(id: "fancy_pants", type: .lifestyle, title: "Fancy Pants",
              description: "Log a glass bottle {drink}. Pinky up.", icon: "wineglass.fill", rarity: .rare),
        Badge(id: "two_liter_legend", type: .lifestyle, title: "2 Liter Legend",
              description: "Log a 2 liter. Sharing? What's that?", icon: "figure.stand", rarity: .rare),

        // Fast food specific
        Badge(id: "mclovin_it", type: .lifestyle, title: "McLOVIN' It",
              description: "Log 5 McDonald's {drinks}. Ba da ba ba baa.", icon: "m.circle.fill", rarity: .uncommon),
        Badge(id: "chick_fil_a_tier", type: .lifestyle, title: "S-Tier Taste",
              description: "Log 5 Chick-fil-A {drinks}. Except on Sundays.", icon: "c.circle.fill", rarity: .uncommon),

        // Funny combos
        Badge(id: "breakfast_of_champions", type: .lifestyle, title: "Breakfast of Champions",
              description: "Log a {drink} before 9am. Coffee? Never met her.", icon: "cup.and.saucer.fill", rarity: .uncommon),
        Badge(id: "dessert_drink", type: .lifestyle, title: "Dessert Drink",
              description: "Log a {drink} after 9pm. The perfect nightcap.", icon: "moon.fill", rarity: .common),
        Badge(id: "all_nighter", type: .lifestyle, title: "All-Nighter",
              description: "Log {drinks} in 3 different time periods in one day. Morning, afternoon, and night.", icon: "clock.badge.fill", rarity: .rare),

        // Seasonal/special
        Badge(id: "new_year_new_dc", type: .lifestyle, title: "New Year, New Drink",
              description: "Log a {drink} on January 1st. Starting the year right.", icon: "sparkles", rarity: .rare),
        Badge(id: "spooky_sip", type: .lifestyle, title: "Spooky Sip",
              description: "Log a {drink} on Halloween. Trick or treat yourself.", icon: "theatermasks.fill", rarity: .rare),
        Badge(id: "turkey_and_dc", type: .lifestyle, title: "Turkey & Soda",
              description: "Log a {drink} on Thanksgiving. The real side dish.", icon: "leaf.fill", rarity: .rare),
        Badge(id: "holiday_spirit", type: .lifestyle, title: "Holiday Spirit(s)",
              description: "Log a {drink} on Christmas. 'Tis the season to be caffeinated.", icon: "gift.fill", rarity: .rare),

        // Caffeine-free specific
        Badge(id: "plot_twist", type: .lifestyle, title: "Plot Twist",
              description: "Log a caffeine-free {drink}. Chaotic neutral energy.", icon: "arrow.triangle.swap", rarity: .uncommon),
        Badge(id: "sleeping_well", type: .lifestyle, title: "Actually Sleeping Well",
              description: "Log 5 caffeine-free {drinks}. Look at you being responsible.", icon: "bed.double.fill", rarity: .rare),
    ]

    // MARK: - All Badges

    static var all: [Badge] {
        milestones + streaks + volume + variety + specialEditions + lifestyle
    }
}
