import SwiftUI

struct SelectedDrinkPreview: View {
    let type: DrinkType
    var brand: BeverageBrand = .dietCoke
    var specialEdition: SpecialEdition? = nil
    var customOunces: Double? = nil
    var rating: DrinkRating? = nil
    /// When set, the card shows a "Snap your drink" button so the preview
    /// doubles as the photo prompt in the add-drink form.
    var onTakePhoto: (() -> Void)? = nil
    var isCameraAvailable: Bool = true
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var displayOunces: Double {
        customOunces ?? type.ounces
    }

    private var isClassicTheme: Bool {
        themeManager.currentTheme == .classic
    }

    private var accentColor: Color {
        if let edition = specialEdition {
            return edition.toBadge().rarity.color
        }
        return brand.color
    }

    private var primaryTextColor: Color {
        isClassicTheme ? .dietCokeCharcoal : .white
    }

    private var secondaryTextColor: Color {
        isClassicTheme ? .dietCokeDarkSilver : .white.opacity(0.7)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isClassicTheme
                                ? [accentColor.opacity(0.3), accentColor.opacity(0.1)]
                                : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 90, height: 90)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isClassicTheme
                                ? [accentColor.opacity(0.15), accentColor.opacity(0.05)]
                                : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                DrinkIconView(drinkType: type, specialEdition: specialEdition, size: DrinkIconSize.xl)
                    .foregroundStyle(
                        isClassicTheme
                            ? LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                    )
            }

            VStack(spacing: 6) {
                Text(type.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)

                // Brand badge + ounces on same line
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        BrandIconView(brand: brand, size: DrinkIconSize.xs)
                        Text(brand.shortName)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(isClassicTheme ? brand.color : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isClassicTheme ? brand.lightColor : brand.color.opacity(0.3))
                    )

                    HStack(spacing: 3) {
                        Text("\(displayOunces, format: .number.precision(.fractionLength(1))) oz")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(secondaryTextColor)

                        if customOunces != nil {
                            Text("(custom)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(isClassicTheme ? .dietCokeRed : .white.opacity(0.9))
                        }
                    }
                }

                if let edition = specialEdition {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(edition.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(edition.toBadge().rarity.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(edition.toBadge().rarity.color.opacity(0.1))
                    .clipShape(Capsule())
                }

                if let rating = rating {
                    HStack(spacing: 4) {
                        Image(systemName: rating.icon)
                            .font(.caption2)
                        Text(rating.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(rating.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(rating.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            if let onTakePhoto {
                Button(action: onTakePhoto) {
                    Label(isCameraAvailable ? "Snap your drink" : "Camera Unavailable", systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isClassicTheme ? .white : accentColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(isClassicTheme ? AnyShapeStyle(brand.buttonGradient) : AnyShapeStyle(Color.white))
                        )
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(!isCameraAvailable)
                .opacity(isCameraAvailable ? 1 : 0.5)
                .padding(.top, 4)
                .accessibilityLabel(isCameraAvailable ? "Take photo of your drink" : "Camera unavailable")
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    themeManager.currentTheme == .classic
                        ? (colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)
                        : themeManager.primaryGradient
                )
        )
        .overlay {
            AmbientBubblesBackground(bubbleCount: 8)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#if DEBUG
#Preview("Default") {
    SelectedDrinkPreview(type: .regularCan)
        .padding()
        .withPreviewEnvironment()
}

#Preview("Special edition + rating") {
    SelectedDrinkPreview(
        type: .miniCan,
        brand: .dietCoke,
        specialEdition: .america250,
        customOunces: 4.0,
        rating: .transcendent
    )
    .padding()
    .withPreviewEnvironment()
}
#endif
