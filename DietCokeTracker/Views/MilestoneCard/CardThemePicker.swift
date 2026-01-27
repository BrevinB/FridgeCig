import SwiftUI

struct CardThemePicker: View {
    @Binding var selectedTheme: CardTheme
    @EnvironmentObject var purchaseService: PurchaseService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Theme")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeDarkSilver)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardTheme.allCases) { theme in
                        ThemeOption(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            isLocked: theme.isPremium && !purchaseService.isPremium
                        ) {
                            if theme.isPremium && !purchaseService.isPremium {
                                // Show paywall
                            } else {
                                selectedTheme = theme
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct ThemeOption: View {
    let theme: CardTheme
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    // Theme preview
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: theme.icon)
                                .font(.title3)
                                .foregroundColor(theme.accentColor)
                        )

                    // Selection ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dietCokeRed, lineWidth: 3)
                            .frame(width: 56, height: 56)
                    }

                    // Lock overlay
                    if isLocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.4))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }

                Text(theme.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .dietCokeRed : .dietCokeDarkSilver)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CardThemePicker(selectedTheme: .constant(.classic))
        .environmentObject(PurchaseService.shared)
        .padding()
}
