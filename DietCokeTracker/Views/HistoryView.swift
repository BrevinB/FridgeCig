import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DrinkStore
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false

    var groupedEntries: [(date: Date, entries: [DrinkEntry])] {
        let grouped = store.entries.groupedByDay()
        return grouped.keys.sorted(by: >).map { date in
            (date: date, entries: grouped[date]!.sorted { $0.timestamp > $1.timestamp })
        }
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.dietCokeSilver)

            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            Text("Start tracking your Diet Cokes\nand they'll appear here")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryListView: View {
    @EnvironmentObject var store: DrinkStore
    let groupedEntries: [(date: Date, entries: [DrinkEntry])]

    var body: some View {
        List {
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

    var body: some View {
        HStack {
            Text(dateString)
            Spacer()
            Text("\(count) drinks • \(String(format: "%.0f", ounces)) oz")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
    }
}

struct HistoryRowView: View {
    let entry: DrinkEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: entry.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.dietCokeRed)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

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
                }
            }

            Spacer()

            Text("\(String(format: "%.0f", entry.ounces)) oz")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(DrinkStore())
}
