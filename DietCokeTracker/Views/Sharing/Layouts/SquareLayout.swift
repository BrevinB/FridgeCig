import SwiftUI

// MARK: - Square Layout (1:1)

/// Square layout for Instagram feed posts (1080x1080)
struct SquareLayout: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    private var theme: ShareTheme { customization.theme }
    private var accentColor: Color { customization.accentColorOverride ?? theme.accentColor }

    var body: some View {
        VStack(spacing: 0) {
            // Top branding
            if customization.showBranding {
                brandingSection
                    .padding(.top, 50)
            } else {
                Spacer().frame(height: 50)
            }

            Spacer()

            // Main content card
            mainCardSection

            Spacer()

            // Footer
            footerSection
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 50)
    }

    // MARK: - Sections

    private var brandingSection: some View {
        HStack(spacing: 12) {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

            Text("FridgeCig")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryTextColor)
        }
    }

    private var mainCardSection: some View {
        HStack(spacing: 30) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: content.shareIcon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(accentColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text(content.shareTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(content.shareSubtitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accentColor)

                if content.contentType == .weeklyRecap {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(content.shareValue)
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.primaryTextColor)

                        Text("DCs")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
    }

    private var footerSection: some View {
        HStack {
            if customization.showUsername, let username = content.shareUsername ?? customization.username {
                Text("@\(username)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.primaryTextColor)
            }

            Spacer()

            Text(formattedDate)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)
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
struct SquareLayout_Previews: PreviewProvider {
    static var previews: some View {
        SquareLayout(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            customization: ShareCustomization(theme: .classic, format: .instagramPost)
        )
        .frame(width: 1080, height: 1080)
        .previewLayout(.fixed(width: 1080 * 0.2, height: 1080 * 0.2))
    }
}
#endif
