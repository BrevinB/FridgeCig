import SwiftUI

// MARK: - Theme Picker

/// Grid picker for selecting share card themes
struct ThemePicker: View {
    @Binding var selectedTheme: ShareTheme
    let isPremium: Bool
    var onPremiumTap: (() -> Void)?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ShareTheme.allCases) { theme in
                    ShareThemeButton(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        isLocked: theme.isPremium && !isPremium
                    ) {
                        if theme.isPremium && !isPremium {
                            onPremiumTap?()
                        } else {
                            selectedTheme = theme
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Share Theme Button

struct ShareThemeButton: View {
    let theme: ShareTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Theme preview
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 3)
                        )

                    // Lock overlay
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 50, height: 50)

                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .dietCokeRed : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal Theme Picker

/// Horizontally scrollable theme picker
struct HorizontalThemePicker: View {
    @Binding var selectedTheme: ShareTheme
    let isPremium: Bool
    var onPremiumTap: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ShareTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        isLocked: theme.isPremium && !isPremium
                    ) {
                        if theme.isPremium && !isPremium {
                            onPremiumTap?()
                        } else {
                            selectedTheme = theme
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ThemeCard: View {
    let theme: ShareTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Mini card preview
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 100)
                        .overlay(
                            VStack {
                                Image(systemName: theme.icon)
                                    .font(.title3)
                                    .foregroundColor(theme.accentColor)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 3)
                        )

                    // Lock overlay
                    if isLocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 60, height: 100)

                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    }
                }

                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .dietCokeRed : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct ThemePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ThemePicker(
                selectedTheme: .constant(.classic),
                isPremium: false
            )

            HorizontalThemePicker(
                selectedTheme: .constant(.neon),
                isPremium: true
            )
        }
        .padding()
    }
}
#endif
