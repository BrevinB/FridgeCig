import SwiftUI

/// A soft upsell banner that appears at high-engagement moments
struct UpsellBanner: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Gold gradient for premium styling
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 0.9, green: 0.7, blue: 0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(goldGradient.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(goldGradient)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // CTA
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                    Text("PRO")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(goldGradient)
                .clipShape(Capsule())
            }

            // Dismiss
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(goldGradient.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 8,
            y: 2
        )
    }
}

// MARK: - Preset Upsell Banners

extension UpsellBanner {
    /// 5th drink trigger - "Track faster with widgets"
    static func drinkTrigger(onTap: @escaping () -> Void, onDismiss: @escaping () -> Void) -> UpsellBanner {
        UpsellBanner(
            title: "Track faster with widgets",
            subtitle: "Add drinks right from your home screen",
            icon: "square.grid.2x2.fill",
            onTap: onTap,
            onDismiss: onDismiss
        )
    }

    /// First badge trigger - "Share with premium themes"
    static func badgeTrigger(onTap: @escaping () -> Void, onDismiss: @escaping () -> Void) -> UpsellBanner {
        UpsellBanner(
            title: "Share with premium themes",
            subtitle: "Celebrate achievements in style",
            icon: "paintpalette.fill",
            onTap: onTap,
            onDismiss: onDismiss
        )
    }

    /// 7-day streak trigger - "Protect your streak with Pro"
    static func streakTrigger(onTap: @escaping () -> Void, onDismiss: @escaping () -> Void) -> UpsellBanner {
        UpsellBanner(
            title: "Protect your streak",
            subtitle: "Get 3 streak freezes per month with Pro",
            icon: "flame.fill",
            onTap: onTap,
            onDismiss: onDismiss
        )
    }
}

#Preview("Drink Trigger") {
    VStack {
        UpsellBanner.drinkTrigger(onTap: {}, onDismiss: {})
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("Badge Trigger") {
    VStack {
        UpsellBanner.badgeTrigger(onTap: {}, onDismiss: {})
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("Streak Trigger") {
    VStack {
        UpsellBanner.streakTrigger(onTap: {}, onDismiss: {})
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}
