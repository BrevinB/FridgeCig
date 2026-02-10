import SwiftUI

// MARK: - Story Layout (9:16)

/// Vertical layout for Instagram Stories, TikTok (1080x1920)
struct StoryLayout: View {
    let content: any ShareableContent
    let customization: ShareCustomization

    private var theme: ShareTheme { customization.theme }
    private var accentColor: Color { customization.accentColorOverride ?? theme.accentColor }

    var body: some View {
        VStack(spacing: 40) {
            // Top spacing
            Spacer()
                .frame(height: 40)

            // Branding at top
            if customization.showBranding {
                brandingSection
            }

            Spacer()

            // Main card content
            mainCardSection

            Spacer()

            // Footer
            footerSection

            // Bottom spacing
            Spacer()
                .frame(height: 60)
        }
        .padding(.horizontal, 50)
    }

    // MARK: - Sections

    private var brandingSection: some View {
        HStack(spacing: 16) {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            Text("FridgeCig")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryTextColor)
        }
    }

    private var mainCardSection: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: content.shareIcon)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(accentColor)
            }

            // Title & Subtitle
            VStack(spacing: 12) {
                Text(content.shareTitle)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(content.shareSubtitle)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)
            }

            // Value section
            if content.contentType == .weeklyRecap {
                VStack(spacing: 8) {
                    Text(content.shareValue)
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.primaryTextColor)

                    Text("Diet Cokes")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(.vertical, 16)
            } else if content.contentType == .milestone {
                Text(content.shareValue)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Stats
            if !content.shareStats.isEmpty {
                statsSection
            }

            // Fun fact
            if let funFact = content.shareFunFact {
                Text(funFact)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        )
    }

    private var statsSection: some View {
        HStack(spacing: 24) {
            ForEach(content.shareStats.prefix(3)) { stat in
                VStack(spacing: 8) {
                    if let icon = stat.icon {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }
                    Text(stat.value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.primaryTextColor)
                    Text(stat.label)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(accentColor.opacity(0.1))
        )
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            if customization.showUsername, let username = content.shareUsername ?? customization.username {
                Text("@\(username)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(theme.primaryTextColor)
            }

            Text(formattedDate)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: content.shareDate)
    }
}

// MARK: - Preview

#if DEBUG
struct StoryLayout_Previews: PreviewProvider {
    static var previews: some View {
        StoryLayout(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            customization: .milestoneDefault
        )
        .frame(width: 1080, height: 1920)
        .previewLayout(.fixed(width: 1080 * 0.15, height: 1920 * 0.15))
    }
}
#endif
