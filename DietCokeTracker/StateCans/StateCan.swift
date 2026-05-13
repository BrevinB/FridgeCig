import Foundation

struct StateCan: Identifiable, Codable, Equatable, Hashable {
    let code: String
    let name: String
    let symbol: String
    let icon: String

    var id: String { code }
}

extension StateCan {
    static let all: [StateCan] = [
        StateCan(code: "AL", name: "Alabama", symbol: "Yellowhammer", icon: "bird.fill"),
        StateCan(code: "AK", name: "Alaska", symbol: "Northern Lights", icon: "sparkles"),
        StateCan(code: "AZ", name: "Arizona", symbol: "Grand Canyon", icon: "mountain.2.fill"),
        StateCan(code: "AR", name: "Arkansas", symbol: "Diamond State", icon: "diamond.fill"),
        StateCan(code: "CA", name: "California", symbol: "Golden Gate", icon: "sun.max.fill"),
        StateCan(code: "CO", name: "Colorado", symbol: "Rocky Mountains", icon: "mountain.2.fill"),
        StateCan(code: "CT", name: "Connecticut", symbol: "Charter Oak", icon: "leaf.fill"),
        StateCan(code: "DE", name: "Delaware", symbol: "First State", icon: "1.circle.fill"),
        StateCan(code: "DC", name: "D.C.", symbol: "Capitol Dome", icon: "building.columns.fill"),
        StateCan(code: "FL", name: "Florida", symbol: "Sunshine State", icon: "sun.max.fill"),
        StateCan(code: "GA", name: "Georgia", symbol: "Peach State", icon: "leaf.fill"),
        StateCan(code: "HI", name: "Hawaii", symbol: "Aloha State", icon: "sun.haze.fill"),
        StateCan(code: "ID", name: "Idaho", symbol: "Gem State", icon: "sparkles"),
        StateCan(code: "IL", name: "Illinois", symbol: "Land of Lincoln", icon: "star.fill"),
        StateCan(code: "IN", name: "Indiana", symbol: "Hoosier State", icon: "checkerboard.rectangle"),
        StateCan(code: "IA", name: "Iowa", symbol: "Hawkeye State", icon: "eye.fill"),
        StateCan(code: "KS", name: "Kansas", symbol: "Sunflower State", icon: "sun.max.circle.fill"),
        StateCan(code: "KY", name: "Kentucky", symbol: "Bluegrass State", icon: "music.note"),
        StateCan(code: "LA", name: "Louisiana", symbol: "Pelican State", icon: "bird.fill"),
        StateCan(code: "ME", name: "Maine", symbol: "Pine Tree State", icon: "tree.fill"),
        StateCan(code: "MD", name: "Maryland", symbol: "Old Line State", icon: "flag.fill"),
        StateCan(code: "MA", name: "Massachusetts", symbol: "Bay State", icon: "water.waves"),
        StateCan(code: "MI", name: "Michigan", symbol: "Great Lakes", icon: "drop.fill"),
        StateCan(code: "MN", name: "Minnesota", symbol: "North Star", icon: "star.fill"),
        StateCan(code: "MS", name: "Mississippi", symbol: "Magnolia State", icon: "leaf.fill"),
        StateCan(code: "MO", name: "Missouri", symbol: "Show-Me State", icon: "arch.fill"),
        StateCan(code: "MT", name: "Montana", symbol: "Big Sky", icon: "cloud.sun.fill"),
        StateCan(code: "NE", name: "Nebraska", symbol: "Cornhusker State", icon: "leaf.arrow.triangle.circlepath"),
        StateCan(code: "NV", name: "Nevada", symbol: "Silver State", icon: "dice.fill"),
        StateCan(code: "NH", name: "New Hampshire", symbol: "Granite State", icon: "mountain.2.fill"),
        StateCan(code: "NJ", name: "New Jersey", symbol: "Garden State", icon: "leaf.fill"),
        StateCan(code: "NM", name: "New Mexico", symbol: "Land of Enchantment", icon: "sun.dust.fill"),
        StateCan(code: "NY", name: "New York", symbol: "Empire State", icon: "building.2.fill"),
        StateCan(code: "NC", name: "North Carolina", symbol: "Tar Heel State", icon: "airplane"),
        StateCan(code: "ND", name: "North Dakota", symbol: "Peace Garden", icon: "leaf.circle.fill"),
        StateCan(code: "OH", name: "Ohio", symbol: "Buckeye State", icon: "leaf.fill"),
        StateCan(code: "OK", name: "Oklahoma", symbol: "Sooner State", icon: "tornado"),
        StateCan(code: "OR", name: "Oregon", symbol: "Beaver State", icon: "tree.fill"),
        StateCan(code: "PA", name: "Pennsylvania", symbol: "Keystone State", icon: "bell.fill"),
        StateCan(code: "PR", name: "Puerto Rico", symbol: "Isla del Encanto", icon: "sun.haze.fill"),
        StateCan(code: "RI", name: "Rhode Island", symbol: "Ocean State", icon: "water.waves"),
        StateCan(code: "SC", name: "South Carolina", symbol: "Palmetto State", icon: "tree.fill"),
        StateCan(code: "SD", name: "South Dakota", symbol: "Mount Rushmore", icon: "mountain.2.fill"),
        StateCan(code: "TN", name: "Tennessee", symbol: "Volunteer State", icon: "guitars.fill"),
        StateCan(code: "TX", name: "Texas", symbol: "Lone Star", icon: "star.fill"),
        StateCan(code: "UT", name: "Utah", symbol: "Beehive State", icon: "hexagon.fill"),
        StateCan(code: "VT", name: "Vermont", symbol: "Green Mountain", icon: "tree.fill"),
        StateCan(code: "VA", name: "Virginia", symbol: "Old Dominion", icon: "building.columns.fill"),
        StateCan(code: "WA", name: "Washington", symbol: "Evergreen State", icon: "tree.fill"),
        StateCan(code: "WV", name: "West Virginia", symbol: "Mountain State", icon: "mountain.2.fill"),
        StateCan(code: "WI", name: "Wisconsin", symbol: "Badger State", icon: "circle.hexagongrid.fill"),
        StateCan(code: "WY", name: "Wyoming", symbol: "Equality State", icon: "sun.horizon.fill"),
    ]

    static let byCode: [String: StateCan] = Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    /// Maps GeoJSON `properties.name` values to state codes.
    static let codeByGeoJSONName: [String: String] = [
        "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
        "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
        "District of Columbia": "DC", "Florida": "FL", "Georgia": "GA", "Hawaii": "HI",
        "Idaho": "ID", "Illinois": "IL", "Indiana": "IN", "Iowa": "IA",
        "Kansas": "KS", "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME",
        "Maryland": "MD", "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
        "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
        "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM",
        "New York": "NY", "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH",
        "Oklahoma": "OK", "Oregon": "OR", "Pennsylvania": "PA", "Puerto Rico": "PR",
        "Rhode Island": "RI", "South Carolina": "SC", "South Dakota": "SD", "Tennessee": "TN",
        "Texas": "TX", "Utah": "UT", "Vermont": "VT", "Virginia": "VA",
        "Washington": "WA", "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY",
    ]
}
