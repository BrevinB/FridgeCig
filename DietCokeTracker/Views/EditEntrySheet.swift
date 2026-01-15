import SwiftUI

struct EditEntrySheet: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.dismiss) private var dismiss

    let entry: DrinkEntry
    @State private var selectedDateTime: Date

    init(entry: DrinkEntry) {
        self.entry = entry
        _selectedDateTime = State(initialValue: entry.timestamp)
    }

    private var accentColor: Color {
        if let edition = entry.specialEdition {
            return edition.toBadge().rarity.color
        }
        return .dietCokeRed
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Entry info header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 56, height: 56)

                        Image(systemName: entry.specialEdition?.icon ?? entry.type.icon)
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(entry.type.displayName)
                                .font(.headline)
                                .foregroundColor(.dietCokeCharcoal)

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

                        Text("\(String(format: "%.0f", entry.ounces)) oz")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    Spacer()
                }
                .padding()
                .dietCokeCard()

                // Date & Time picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date & Time")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    DatePicker(
                        "",
                        selection: $selectedDateTime,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.dietCokeRed)
                }
                .padding()
                .dietCokeCard()

                Spacer()

                // Save button
                Button {
                    store.updateTimestamp(for: entry, timestamp: selectedDateTime)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.dietCokePrimary)
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dietCokeRed)
                }
            }
        }
    }
}

#Preview {
    EditEntrySheet(entry: DrinkEntry(type: .regularCan))
        .environmentObject(DrinkStore())
}
