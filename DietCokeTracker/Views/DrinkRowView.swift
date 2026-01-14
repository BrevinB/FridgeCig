import SwiftUI

struct DrinkRowView: View {
    let entry: DrinkEntry

    private var accentColor: Color {
        if let edition = entry.specialEdition {
            return edition.toBadge().rarity.color
        }
        return .dietCokeRed
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: entry.specialEdition?.icon ?? entry.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
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

                HStack(spacing: 6) {
                    Text(entry.formattedTime)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)

                    Text("\(String(format: "%.0f", entry.ounces)) oz")
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.dietCokeSilver)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        DrinkRowView(entry: DrinkEntry(type: .regularCan))
        DrinkRowView(entry: DrinkEntry(type: .mcdonaldsLarge, note: "Extra ice"))
        DrinkRowView(entry: DrinkEntry(type: .chickfilaMedium))
    }
    .padding()
    .dietCokeCard()
    .padding()
}
