import SwiftUI
import WidgetKit

/// A reusable flame/streak badge view
struct StreakBadgeView: View {
    let streak: Int
    let flameColor: WidgetFlameColor
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large

        var flameSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 48
            }
        }

        var numberSize: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 44
            case .large: return 56
            }
        }
    }

    init(streak: Int, flameColor: WidgetFlameColor = .orange, size: BadgeSize = .medium) {
        self.streak = streak
        self.flameColor = flameColor
        self.size = size
    }

    var body: some View {
        VStack(spacing: 4) {
            // Flame icon with gradient
            Image(systemName: flameIcon)
                .font(.system(size: size.flameSize))
                .foregroundStyle(
                    LinearGradient(
                        colors: flameColor.gradientColors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .symbolEffect(.pulse, options: .repeating, isActive: streak > 0)

            // Streak number
            Text("\(streak)")
                .font(.system(size: size.numberSize, weight: .bold, design: .rounded))
                .foregroundStyle(flameColor.color)
        }
    }

    private var flameIcon: String {
        if streak >= 100 {
            return "flame.fill"
        } else if streak >= 30 {
            return "flame.fill"
        } else {
            return "flame.fill"
        }
    }
}

/// Multiple flame icons based on streak intensity
struct FlameRowView: View {
    let streak: Int
    let flameColor: WidgetFlameColor
    let maxFlames: Int

    init(streak: Int, flameColor: WidgetFlameColor = .orange, maxFlames: Int = 5) {
        self.streak = streak
        self.flameColor = flameColor
        self.maxFlames = maxFlames
    }

    private var numberOfFlames: Int {
        if streak >= 100 { return maxFlames }
        if streak >= 60 { return 4 }
        if streak >= 30 { return 3 }
        if streak >= 14 { return 2 }
        if streak >= 7 { return 1 }
        return 1
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<numberOfFlames, id: \.self) { index in
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: flameColor.gradientColors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
        }
    }
}

/// Progress bar towards next milestone
struct MilestoneProgressView: View {
    let current: Int
    let next: Int
    let progress: Double
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // Labels
            HStack {
                Text("\(current)")
                    .font(.caption2)
                    .fontWeight(.medium)
                Spacer()
                Text("\(next)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Compact milestone indicator
struct MilestoneIndicatorView: View {
    let nextMilestone: Int
    let encouragement: String

    var body: some View {
        VStack(spacing: 2) {
            Text("Next: \(nextMilestone)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(encouragement)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Previews

#Preview("Streak Badge Small") {
    StreakBadgeView(streak: 42, size: .small)
        .padding()
}

#Preview("Streak Badge Medium") {
    StreakBadgeView(streak: 42, size: .medium)
        .padding()
}

#Preview("Streak Badge Large") {
    StreakBadgeView(streak: 42, flameColor: .blue, size: .large)
        .padding()
}

#Preview("Flame Row") {
    VStack(spacing: 20) {
        FlameRowView(streak: 5)
        FlameRowView(streak: 14)
        FlameRowView(streak: 30)
        FlameRowView(streak: 60)
        FlameRowView(streak: 100)
    }
    .padding()
}

#Preview("Milestone Progress") {
    MilestoneProgressView(current: 42, next: 60, progress: 0.67, accentColor: .orange)
        .frame(width: 150)
        .padding()
}
