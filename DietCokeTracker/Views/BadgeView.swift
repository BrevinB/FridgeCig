import SwiftUI

struct BadgeView: View {
    let badge: Badge
    var size: BadgeSize = .medium
    var showDetails: Bool = true
    var brand: BeverageBrand = .dietCoke

    private var dynamicDescription: String {
        badge.description(for: brand)
    }

    var body: some View {
        VStack(spacing: size.spacing) {
            ZStack {
                // Background circle with rarity color
                Circle()
                    .fill(badge.isUnlocked ? badge.rarity.color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: size.circleSize, height: size.circleSize)

                // Rarity ring
                Circle()
                    .stroke(
                        badge.isUnlocked ? badge.rarity.color : Color.gray.opacity(0.3),
                        lineWidth: size.ringWidth
                    )
                    .frame(width: size.circleSize, height: size.circleSize)

                // Icon
                Image(systemName: badge.icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(badge.isUnlocked ? badge.rarity.color : Color.gray.opacity(0.4))

                // Lock overlay for locked badges
                if !badge.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: size.circleSize, height: size.circleSize)

                    Image(systemName: "lock.fill")
                        .font(.system(size: size.iconSize * 0.5))
                        .foregroundColor(.white)
                }
            }

            if showDetails {
                VStack(spacing: 2) {
                    Text(badge.title)
                        .font(size.titleFont)
                        .fontWeight(.semibold)
                        .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if size == .large {
                        Text(dynamicDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .frame(width: size.circleSize + 20)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.title), \(badge.rarity.displayName) badge\(badge.isUnlocked ? ", earned" : ", locked")")
        .accessibilityHint(badge.isUnlocked ? dynamicDescription : "Not yet unlocked: \(dynamicDescription)")
    }
}

// MARK: - Badge Size

enum BadgeSize {
    case small
    case medium
    case large
    case share

    var circleSize: CGFloat {
        switch self {
        case .small: return 50
        case .medium: return 70
        case .large: return 90
        case .share: return 120
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        case .share: return 48
        }
    }

    var ringWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        case .share: return 5
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .share: return 12
        }
    }

    var titleFont: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        case .share: return .headline
        }
    }
}

// MARK: - Badge Grid Item

struct BadgeGridItem: View {
    let badge: Badge
    var brand: BeverageBrand = .dietCoke
    var onTap: (() -> Void)?

    private var backgroundGradient: LinearGradient {
        if badge.isUnlocked {
            return LinearGradient(
                colors: [
                    badge.rarity.color.opacity(0.2),
                    badge.rarity.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderColor: Color {
        badge.isUnlocked ? badge.rarity.color.opacity(0.4) : Color.gray.opacity(0.2)
    }

    private var shadowColor: Color {
        badge.isUnlocked ? badge.rarity.color.opacity(0.25) : Color.clear
    }

    var body: some View {
        Button(action: { onTap?() }) {
            BadgeView(badge: badge, size: .medium, brand: brand)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
                .shadow(color: shadowColor, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(badge.title), \(badge.rarity.displayName) badge\(badge.isUnlocked ? "" : ", locked")")
        .accessibilityHint(badge.isUnlocked ? "Double tap to view details and share" : "Not yet unlocked")
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: Badge
    var brand: BeverageBrand = .dietCoke
    @Environment(\.dismiss) private var dismiss
    var onShare: (() -> Void)? = nil
    @State private var shareImage: UIImage?

    private var dynamicDescription: String {
        badge.description(for: brand)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Colored header card
                    VStack(spacing: 16) {
                        BadgeView(badge: badge, size: .large, brand: brand)
                            .padding(.top, 8)

                        HStack(spacing: 8) {
                            Text(badge.rarity.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(badge.rarity.color.gradient)
                                )

                            Text(badge.type.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(badge.rarity.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(badge.rarity.color.opacity(0.15))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(
                            colors: [
                                badge.rarity.color.opacity(0.25),
                                badge.rarity.color.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Content
                    VStack(spacing: 16) {
                        Text(dynamicDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        if let unlockDate = badge.formattedUnlockDate {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Earned on \(unlockDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if badge.isUnlocked {
                            if let image = shareImage {
                                ShareLink(
                                    item: Image(uiImage: image),
                                    preview: SharePreview(
                                        "\(brand.shortName) Badge: \(badge.title)",
                                        image: Image(uiImage: image)
                                    )
                                ) {
                                    Label("Share Badge", systemImage: "square.and.arrow.up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [badge.rarity.color, badge.rarity.color.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: badge.rarity.color.opacity(0.4), radius: 8, y: 4)
                                }
                                .padding(.top, 16)
                            } else {
                                ProgressView()
                                    .padding(.top, 16)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(badge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateShareImage()
            }
        }
    }

    private func generateShareImage() {
        let renderer = ImageRenderer(content: ShareableBadgeView(badge: badge, brand: brand))
        renderer.scale = 3.0
        shareImage = renderer.uiImage
    }
}

// MARK: - Badge Unlock Toast

struct BadgeUnlockToast: View {
    let badge: Badge
    var brand: BeverageBrand = .dietCoke
    var onDismiss: () -> Void
    var onShare: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.0
    @State private var isPulsing: Bool = false

    private var dynamicDescription: String {
        badge.description(for: brand)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header with subtle styling
            Text("Achievement Unlocked")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .textCase(.uppercase)
                .tracking(1.5)

            // Badge icon with glow effect
            ZStack {
                // Outer glow with pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [badge.rarity.color.opacity(0.5), badge.rarity.color.opacity(0)],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(isPulsing ? 1.15 : 0.95)
                    .opacity(glowOpacity)

                // Badge background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                badge.rarity.color.opacity(0.3),
                                badge.rarity.color.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Border ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.9),
                                badge.rarity.color
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                // Icon
                Image(systemName: badge.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(iconScale)
            }

            // Badge info
            VStack(spacing: 8) {
                Text(badge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(dynamicDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Rarity pill
                Text(badge.rarity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        Text("Share")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(badge.rarity.color)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
                }

                Button(action: onDismiss) {
                    Text("Continue")
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(
            ZStack {
                // Colored glassmorphism background
                RoundedRectangle(cornerRadius: 28)
                    .fill(badge.rarity.color.gradient)

                // Glass overlay
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial.opacity(0.5))

                // Subtle gradient overlay for depth
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: badge.rarity.color.opacity(0.4), radius: 30, y: 15)
        .onAppear {
            // Animate icon entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            // Animate glow
            withAnimation(.easeOut(duration: 0.8)) {
                glowOpacity = 1.0
            }
            // Start pulsing
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Badge View - Unlocked") {
    let badge = Badge(
        id: "test",
        type: .milestone,
        title: "First Sip",
        description: "Log your first DC",
        icon: "flask.fill",
        rarity: .common,
        unlockedAt: Date()
    )
    return BadgeView(badge: badge)
}

#Preview("Badge View - Locked") {
    let badge = Badge(
        id: "test",
        type: .milestone,
        title: "Legend",
        description: "Log 500 DCs",
        icon: "trophy.fill",
        rarity: .epic
    )
    return BadgeView(badge: badge)
}
