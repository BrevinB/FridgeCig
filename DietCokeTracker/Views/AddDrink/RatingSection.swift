import SwiftUI

struct RatingSection: View {
    @Binding var selectedRating: DrinkRating?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Rate this DC")
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

            Text("How was it? (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(DrinkRating.allCases) { rating in
                    RatingButton(
                        rating: rating,
                        isSelected: selectedRating == rating
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedRating == rating {
                                selectedRating = nil
                            } else {
                                selectedRating = rating
                            }
                        }
                    }
                }
            }

            if let rating = selectedRating {
                Text(rating.description)
                    .font(.caption)
                    .foregroundColor(rating.color)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct RatingButton: View {
    let rating: DrinkRating
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: rating.icon)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(rating.displayName)
                    .font(.system(size: 9))
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? rating.color : rating.color.opacity(0.1))
            .foregroundColor(isSelected ? .white : rating.color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate as \(rating.displayName)")
        .accessibilityHint(rating.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
private struct RatingSectionPreviewWrapper: View {
    @State private var rating: DrinkRating? = .crisp
    var body: some View { RatingSection(selectedRating: $rating).padding() }
}

#Preview("Section") { RatingSectionPreviewWrapper() }

#Preview("Button — selected") {
    RatingButton(rating: .crisp, isSelected: true) {}
        .frame(width: 80)
        .padding()
}
#endif
