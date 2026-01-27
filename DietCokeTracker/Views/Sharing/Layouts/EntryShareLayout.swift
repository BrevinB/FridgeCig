import SwiftUI
import UIKit

// MARK: - Entry Share Layout

/// Special layout for sharing individual drink entries
/// Features photo prominently with gradient overlay when available
struct EntryShareLayout: View {
    let entry: DrinkEntry
    let customization: ShareCustomization
    let photo: UIImage?

    private var theme: ShareTheme { customization.theme }
    private var accentColor: Color { customization.accentColorOverride ?? theme.accentColor }

    var body: some View {
        if let photo = photo {
            // Photo layout with overlay
            photoLayout(photo: photo)
        } else {
            // Standard layout without photo
            standardLayout
        }
    }

    // MARK: - Photo Layout

    private func photoLayout(photo: UIImage) -> some View {
        ZStack {
            // Full-bleed photo
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: customization.format.width, height: customization.format.height)
                .clipped()

            // Gradient overlay for readability - stronger gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            VStack(spacing: 0) {
                // Top branding
                if customization.showBranding {
                    topBranding
                        .padding(.top, 80)
                }

                Spacer()

                // Bottom content card
                bottomContentCard
                    .padding(.horizontal, 48)
                    .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Standard Layout (no photo)

    private var standardLayout: some View {
        VStack(spacing: 0) {
            // Top branding
            if customization.showBranding {
                brandingSection
                    .padding(.top, 80)
                    .padding(.bottom, 40)
            } else {
                Spacer().frame(height: 80)
            }

            // Main card - fills most of the space
            mainCardSection
                .padding(.horizontal, 60)

            Spacer().frame(minHeight: 40, maxHeight: 60)

            // Footer
            footerSection
                .padding(.bottom, 80)
        }
    }

    // MARK: - Photo Layout Components

    private var topBranding: some View {
        HStack(spacing: 18) {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)

            Text("FridgeCig")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .blur(radius: 2)
        )
    }

    private var bottomContentCard: some View {
        VStack(spacing: 24) {
            // Icon and brand
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 80, height: 80)

                    Image(systemName: entry.type.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.brand.shortName)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(entry.type.rawValue)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Size badge
                Text("\(Int(entry.ounces))oz")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
            }

            // Rating and special edition
            if entry.rating != nil || entry.specialEdition != nil {
                HStack(spacing: 20) {
                    if let rating = entry.rating {
                        HStack(spacing: 8) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < rating.rawValue ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(index < rating.rawValue ? .yellow : .white.opacity(0.3))
                            }
                        }
                    }

                    if let special = entry.specialEdition {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text(special.rawValue)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 20, weight: .semibold))
                    }

                    Spacer()
                }
            }

            // Note if available
            if let note = entry.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .italic()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Date and username
            HStack {
                Text(entry.formattedDateTime)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if customization.showUsername, let username = customization.username {
                    Text("@\(username)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Standard Layout Components

    private var brandingSection: some View {
        HStack(spacing: 24) {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)

            Text("FridgeCig")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryTextColor)
        }
    }

    private var mainCardSection: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 220, height: 220)

                Image(systemName: entry.type.icon)
                    .font(.system(size: 100, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            Spacer().frame(height: 60)

            // Brand and type
            VStack(spacing: 24) {
                Text(entry.brand.shortName)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryTextColor)
                    .multilineTextAlignment(.center)

                Text(entry.type.rawValue)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(accentColor)

                Text("\(Int(entry.ounces)) oz")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.primaryTextColor)
                    .padding(.top, 16)
            }

            Spacer().frame(height: 50)

            // Rating
            if let rating = entry.rating {
                HStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating.rawValue ? "star.fill" : "star")
                            .font(.system(size: 48))
                            .foregroundColor(index < rating.rawValue ? .yellow : theme.secondaryTextColor.opacity(0.3))
                    }
                }
                Spacer().frame(height: 40)
            }

            // Special edition
            if let special = entry.specialEdition {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text(special.rawValue)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .font(.system(size: 36, weight: .semibold))
                Spacer().frame(height: 40)
            }

            // Note
            if let note = entry.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer().frame(height: 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 50)
        .background(
            RoundedRectangle(cornerRadius: 48)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
        )
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            if customization.showUsername, let username = customization.username {
                Text("@\(username)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.primaryTextColor)
            }

            Text(entry.formattedDateTime)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - ShareCustomization Extension

extension ShareCustomization {
    /// Username for attribution (stored separately from content)
    var username: String? {
        // This could be loaded from user defaults or passed in
        UserDefaults.standard.string(forKey: "username")
    }
}

// MARK: - Preview

#if DEBUG
struct EntryShareLayout_Previews: PreviewProvider {
    static var previews: some View {
        let entry = DrinkEntry(
            type: .regularCan,
            brand: .dietCoke,
            note: "Perfect afternoon pick-me-up!",
            rating: .crisp
        )

        EntryShareLayout(
            entry: entry,
            customization: .milestoneDefault,
            photo: nil
        )
        .frame(width: 1080, height: 1920)
        .previewLayout(.fixed(width: 1080 * 0.15, height: 1920 * 0.15))
    }
}
#endif
