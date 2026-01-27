import SwiftUI

struct MilestoneCardView: View {
    let card: MilestoneCard
    let theme: CardTheme
    var isCompact: Bool = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                .fill(
                    LinearGradient(
                        colors: theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: isCompact ? 12 : 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: isCompact ? 50 : 80, height: isCompact ? 50 : 80)

                    Image(systemName: card.icon)
                        .font(.system(size: isCompact ? 24 : 40))
                        .foregroundColor(theme.accentColor)
                }

                // Title
                Text(card.title)
                    .font(isCompact ? .title3 : .largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryTextColor)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(card.subtitle)
                    .font(isCompact ? .subheadline : .title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)

                if !isCompact {
                    // Value/Description
                    Text(card.value)
                        .font(.body)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Badge rarity indicator
                if let rarity = card.badgeRarity {
                    Text(rarity.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(rarity.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(rarity.color.opacity(0.2))
                        )
                }
            }
            .padding(isCompact ? 16 : 32)
        }
        .aspectRatio(isCompact ? 1.5 : 9.0/16.0, contentMode: .fit)
    }
}

// MARK: - Preview Card (in-app display)

struct MilestoneCardPreviewView: View {
    let card: MilestoneCard
    @Binding var selectedTheme: CardTheme
    let onShare: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Card Preview
            MilestoneCardView(card: card, theme: selectedTheme)
                .frame(maxWidth: 300)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

            // Theme Picker
            CardThemePicker(selectedTheme: $selectedTheme)

            // Actions
            HStack(spacing: 16) {
                Button {
                    onDismiss()
                } label: {
                    Text("Later")
                        .font(.headline)
                        .foregroundColor(.dietCokeDarkSilver)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                        )
                }

                Button {
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.dietCokeRed)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .padding(20)
    }
}

#Preview {
    VStack(spacing: 20) {
        MilestoneCardView(
            card: MilestoneCard.forDrinkCount(100, username: "DCFan"),
            theme: .classic
        )
        .frame(height: 400)

        MilestoneCardView(
            card: MilestoneCard.forStreak(30),
            theme: .neon,
            isCompact: true
        )
        .frame(height: 150)
    }
    .padding()
}
