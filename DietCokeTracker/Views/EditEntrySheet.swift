import SwiftUI

struct EditEntrySheet: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.dismiss) private var dismiss

    let entry: DrinkEntry
    @State private var selectedDateTime: Date
    @State private var selectedRating: DrinkRating?

    init(entry: DrinkEntry) {
        self.entry = entry
        _selectedDateTime = State(initialValue: entry.timestamp)
        _selectedRating = State(initialValue: entry.rating)
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

                        HStack(spacing: 4) {
                            Text("\(String(format: "%.0f", entry.ounces)) oz")
                                .font(.subheadline)
                                .foregroundColor(.dietCokeDarkSilver)

                            if entry.hasCustomOunces {
                                Text("(custom)")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeRed)
                            }
                        }
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

                // Rating section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Rating")
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)

                        Spacer()

                        if selectedRating != nil {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedRating = nil
                                }
                            } label: {
                                Text("Clear")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeRed)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(DrinkRating.allCases) { rating in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedRating == rating {
                                        selectedRating = nil
                                    } else {
                                        selectedRating = rating
                                    }
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: rating.icon)
                                        .font(.title3)
                                    Text(rating.displayName)
                                        .font(.system(size: 9))
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedRating == rating ? rating.color : rating.color.opacity(0.1))
                                .foregroundColor(selectedRating == rating ? .white : rating.color)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let rating = selectedRating {
                        Text(rating.description)
                            .font(.caption)
                            .foregroundColor(rating.color)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .dietCokeCard()

                Spacer()

                // Save button
                Button {
                    store.updateTimestamp(for: entry, timestamp: selectedDateTime)
                    store.updateRating(for: entry, rating: selectedRating)
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
