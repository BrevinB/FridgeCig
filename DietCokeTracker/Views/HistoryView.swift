import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @Environment(\.colorScheme) private var colorScheme

    var groupedEntries: [(date: Date, entries: [DrinkEntry])] {
        let grouped = store.entries.groupedByDay()
        return grouped.keys.sorted(by: >).map { date in
            (date: date, entries: grouped[date]!.sorted { $0.timestamp > $1.timestamp })
        }
    }

    private var backgroundColor: Color {
        themeManager.backgroundColor(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    EmptyHistoryView()
                } else {
                    HistoryListView(groupedEntries: groupedEntries)
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("History")
        }
    }
}

// MARK: - History Hero Card

struct HistoryHeroCard: View {
    let totalDays: Int
    let totalDrinks: Int
    let totalOunces: Double
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background - metallic for classic, themed gradient for premium themes
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    themeManager.currentTheme == .classic
                        ? (colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)
                        : themeManager.primaryGradient
                )

            // Subtle fizz bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Content
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        themeManager.currentTheme == .classic
                            ? AnyShapeStyle(LinearGradient(colors: [Color.dietCokeRed, Color.dietCokeDeepRed], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.white)
                    )

                Text("Your DC Journey")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeCharcoal : .white)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(totalDays)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeRed : .white)
                        Text("Days")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeDarkSilver : .white.opacity(0.7))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(totalDays) days")

                    Rectangle()
                        .fill(themeManager.currentTheme == .classic ? Color.dietCokeSilver.opacity(0.3) : Color.white.opacity(0.3))
                        .frame(width: 1, height: 40)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("\(totalDrinks)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeRed : .white)
                        Text("Drinks")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeDarkSilver : .white.opacity(0.7))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(totalDrinks) drinks")

                    Rectangle()
                        .fill(themeManager.currentTheme == .classic ? Color.dietCokeSilver.opacity(0.3) : Color.white.opacity(0.3))
                        .frame(width: 1, height: 40)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("\(String(format: "%.0f", totalOunces))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeRed : .white)
                        Text("Ounces")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme == .classic ? .dietCokeDarkSilver : .white.opacity(0.7))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(String(format: "%.0f", totalOunces)) ounces")
                }
            }
            .padding(.vertical, 20)
        }
        .frame(height: 180)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your Diet Coke journey: \(totalDays) days, \(totalDrinks) drinks, \(String(format: "%.0f", totalOunces)) ounces")
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 10,
            y: 4
        )
    }
}

struct EmptyHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dietCokeSilver.opacity(0.2),
                                Color.dietCokeSilver.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeSilver, Color.dietCokeDarkSilver],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No History Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Start tracking your DCs\nand they'll appear here")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryListView: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme
    let groupedEntries: [(date: Date, entries: [DrinkEntry])]

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var totalEntries: Int {
        groupedEntries.reduce(0) { $0 + $1.entries.count }
    }

    private var totalOunces: Double {
        groupedEntries.reduce(0) { $0 + $1.entries.totalOunces }
    }

    var body: some View {
        List {
            // Hero Section
            Section {
                HistoryHeroCard(
                    totalDays: groupedEntries.count,
                    totalDrinks: totalEntries,
                    totalOunces: totalOunces
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            ForEach(groupedEntries, id: \.date) { group in
                Section {
                    ForEach(group.entries) { entry in
                        HistoryRowView(entry: entry)
                    }
                    .onDelete { offsets in
                        deleteEntries(at: offsets, from: group.entries)
                    }
                } header: {
                    HistorySectionHeader(
                        date: group.date,
                        count: group.entries.count,
                        ounces: group.entries.totalOunces
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(backgroundColor)
    }

    private func deleteEntries(at offsets: IndexSet, from entries: [DrinkEntry]) {
        for index in offsets {
            store.deleteEntry(entries[index])
        }
    }
}

struct HistorySectionHeader: View {
    let date: Date
    let count: Int
    let ounces: Double

    var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                if isToday {
                    Circle()
                        .fill(Color.dietCokeRed)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(dateString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? .dietCokeRed : .dietCokeCharcoal)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("\(count)")
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeRed)
                Text("drinks •")
                    .foregroundColor(.dietCokeDarkSilver)
                Text("\(String(format: "%.0f", ounces)) oz")
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
            }
            .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dateString): \(count) drinks, \(String(format: "%.0f", ounces)) ounces")
    }
}

struct HistoryRowView: View {
    let entry: DrinkEntry
    @State private var showingEditSheet = false

    private var accentColor: Color {
        if let edition = entry.specialEdition {
            return edition.toBadge().rarity.color
        }
        return entry.brand.color
    }

    private var iconGradient: LinearGradient {
        if entry.specialEdition != nil {
            return LinearGradient(colors: [accentColor, accentColor], startPoint: .top, endPoint: .bottom)
        }
        return entry.brand.iconGradient
    }

    private var accessibilityDescription: String {
        var parts = ["\(entry.type.displayName)", "\(entry.brand.shortName)", "\(String(format: "%.0f", entry.ounces)) ounces", "at \(entry.formattedTime)"]
        if let edition = entry.specialEdition {
            parts.insert("\(edition.rawValue) special edition", at: 1)
        }
        if let note = entry.note, !note.isEmpty {
            parts.append("note: \(note)")
        }
        if entry.hasPhoto {
            parts.append("has photo")
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(entry.brand.cardGradient)
                    .frame(width: 44, height: 44)

                DrinkIconView(drinkType: entry.type, specialEdition: entry.specialEdition, size: DrinkIconSize.md)
                    .foregroundStyle(iconGradient)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)

                    // Brand badge
                    Text(entry.brand.shortName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(entry.brand.iconGradient)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(entry.brand.lightColor)
                        .clipShape(Capsule())

                    if let edition = entry.specialEdition {
                        Text(edition.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(edition.toBadge().rarity.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(edition.toBadge().rarity.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text(entry.formattedTime)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)

                    if let note = entry.note, !note.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                            .lineLimit(1)
                    }

                    if entry.hasPhoto {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            Spacer()

            Text("\(String(format: "%.0f", entry.ounces)) oz")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.dietCokeSilver)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEntrySheet(entry: entry)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to edit")
    }
}

#Preview {
    HistoryView()
        .environmentObject(DrinkStore())
}
