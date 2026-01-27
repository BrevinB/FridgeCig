import SwiftUI

// MARK: - Gradient Style

enum GradientStyle {
    case linear
    case radial
    case angular
}

// MARK: - Gradient Background

/// Customizable gradient background for share cards
struct GradientBackground: View {
    let colors: [Color]
    let style: GradientStyle

    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing

    var body: some View {
        switch style {
        case .linear:
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )

        case .radial:
            RadialGradient(
                colors: colors,
                center: .center,
                startRadius: 0,
                endRadius: 1000
            )

        case .angular:
            AngularGradient(
                colors: colors + [colors.first ?? .clear],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }
}

// MARK: - Animated Gradient Background

/// Gradient background with subtle animation
struct AnimatedGradientBackground: View {
    let colors: [Color]
    let style: GradientStyle

    @State private var animateGradient = false

    var body: some View {
        GradientBackground(
            colors: colors,
            style: style,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Theme Gradient Helper

extension GradientBackground {
    init(theme: ShareTheme) {
        self.colors = theme.gradientColors
        switch theme.backgroundStyle {
        case .multiGradient:
            self.style = .angular
        default:
            self.style = .linear
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GradientBackground(
                colors: [.red, .orange],
                style: .linear
            )
            .frame(height: 100)

            GradientBackground(
                colors: [.purple, .blue, .cyan],
                style: .radial
            )
            .frame(height: 100)

            GradientBackground(
                colors: [.pink, .purple, .blue, .green, .yellow, .orange, .red],
                style: .angular
            )
            .frame(height: 100)
        }
        .padding()
    }
}
#endif
