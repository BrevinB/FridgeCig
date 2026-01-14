import SwiftUI

struct BadgeView: View {
    let badge: Badge
    var size: BadgeSize = .medium
    var showDetails: Bool = true

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
                        Text(badge.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .frame(width: size.circleSize + 20)
            }
        }
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
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            BadgeView(badge: badge, size: .medium)
                .padding(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    var onShare: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                BadgeView(badge: badge, size: .large)

                VStack(spacing: 8) {
                    HStack {
                        Text(badge.rarity.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(badge.rarity.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(badge.rarity.color.opacity(0.15))
                            .clipShape(Capsule())

                        Text(badge.type.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Text(badge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let unlockDate = badge.formattedUnlockDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Earned on \(unlockDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer()

                if badge.isUnlocked {
                    Button(action: { onShare?() }) {
                        Label("Share Badge", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.dietCokePrimary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(badge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Badge Unlock Toast

struct BadgeUnlockToast: View {
    let badge: Badge
    var onDismiss: () -> Void
    var onShare: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Badge Unlocked!")
                .font(.headline)
                .foregroundColor(.white)

            ZStack {
                Circle()
                    .fill(badge.rarity.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)

                Circle()
                    .stroke(badge.rarity.color, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Image(systemName: badge.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(badge.rarity.color)
            }

            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(badge.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Text(badge.rarity.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(badge.rarity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(badge.rarity.color.opacity(0.2))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Button("Share") {
                    onShare()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(8)

                Button("Dismiss") {
                    onDismiss()
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dietCokeCharcoal)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
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
        description: "Log your first Diet Coke",
        icon: "drop.fill",
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
        description: "Log 500 Diet Cokes",
        icon: "trophy.fill",
        rarity: .epic
    )
    return BadgeView(badge: badge)
}
