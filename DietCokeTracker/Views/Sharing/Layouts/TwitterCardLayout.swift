import SwiftUI

// MARK: - Twitter Card Layout (16:9)

/// Horizontal layout for Twitter cards (1200x675)
struct TwitterCardLayout: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    private var theme: ShareTheme { customization.theme }
    private var accentColor: Color { customization.accentColorOverride ?? theme.accentColor }

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Branding & Icon
            leftSection
                .frame(width: 280)

            // Right side - Content
            rightSection
        }
        .padding(40)
    }

    // MARK: - Sections

    private var leftSection: some View {
        VStack(spacing: 24) {
            // Branding
            if customization.showBranding {
                HStack(spacing: 10) {
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                    Text("FridgeCig")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryTextColor)
                }
            }

            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: content.shareIcon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(accentColor)
            }

            Spacer()

            // Date
            Text(formattedDate)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.trailing, 20)
    }

    private var rightSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Main content
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(content.shareTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Subtitle
                Text(content.shareSubtitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accentColor)

                // Value for recaps
                if content.contentType == .weeklyRecap {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(content.shareValue)
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.primaryTextColor)

                        Text("Diet Cokes")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding(.top, 8)
                }

                // Stats (compact horizontal)
                if !content.shareStats.isEmpty {
                    HStack(spacing: 20) {
                        ForEach(content.shareStats.prefix(3)) { stat in
                            HStack(spacing: 6) {
                                if let icon = stat.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(accentColor)
                                }
                                Text(stat.value)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(theme.primaryTextColor)
                                Text(stat.label)
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            )

            Spacer()

            // Username at bottom
            if customization.showUsername, let username = content.shareUsername {
                Text("@\(username)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primaryTextColor)
                    .padding(.top, 16)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: content.shareDate)
    }
}

// MARK: - Preview

#if DEBUG
struct TwitterCardLayout_Previews: PreviewProvider {
    static var previews: some View {
        TwitterCardLayout(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            customization: ShareCustomization(theme: .classic, format: .twitterCard)
        )
        .frame(width: 1200, height: 675)
        .previewLayout(.fixed(width: 1200 * 0.2, height: 675 * 0.2))
    }
}
#endif
