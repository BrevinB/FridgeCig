import SwiftUI

// MARK: - Decorative Shapes

/// Subtle decorative shapes for themed share cards (rendered behind content)
struct DecorativeShapes: View {
    let theme: ShareTheme
    let format: ShareFormat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch theme {
                case .neon:
                    neonShapes(in: geometry.size)
                case .gradient90s:
                    retro90sShapes(in: geometry.size)
                case .pastel:
                    pastelShapes(in: geometry.size)
                default:
                    EmptyView()
                }
            }
            .opacity(theme.decorativeShapeOpacity)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Neon Theme Shapes

    @ViewBuilder
    private func neonShapes(in size: CGSize) -> some View {
        // Subtle glowing circles in corners
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.pink.opacity(0.4), Color.pink.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.3
                )
            )
            .frame(width: size.width * 0.5)
            .position(x: size.width * 0.1, y: size.height * 0.15)

        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.purple.opacity(0.3), Color.purple.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.25
                )
            )
            .frame(width: size.width * 0.4)
            .position(x: size.width * 0.9, y: size.height * 0.85)
    }

    // MARK: - 90s Retro Shapes

    @ViewBuilder
    private func retro90sShapes(in size: CGSize) -> some View {
        // Colorful geometric accents in corners
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.orange.opacity(0.4), Color.orange.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.2
                )
            )
            .frame(width: size.width * 0.35)
            .position(x: size.width * 0.05, y: size.height * 0.1)

        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.15
                )
            )
            .frame(width: size.width * 0.25)
            .position(x: size.width * 0.95, y: size.height * 0.2)

        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.pink.opacity(0.35), Color.pink.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.2
                )
            )
            .frame(width: size.width * 0.3)
            .position(x: size.width * 0.9, y: size.height * 0.9)
    }

    // MARK: - Pastel Shapes

    @ViewBuilder
    private func pastelShapes(in size: CGSize) -> some View {
        // Soft gradient blobs - fixed positions for consistency
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.9).opacity(0.5),
                        Color(red: 1.0, green: 0.8, blue: 0.9).opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.25
                )
            )
            .frame(width: size.width * 0.5, height: size.width * 0.4)
            .position(x: size.width * 0.15, y: size.height * 0.1)

        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.8, green: 0.9, blue: 1.0).opacity(0.4),
                        Color(red: 0.8, green: 0.9, blue: 1.0).opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.2
                )
            )
            .frame(width: size.width * 0.4, height: size.width * 0.35)
            .position(x: size.width * 0.85, y: size.height * 0.85)

        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.85, green: 1.0, blue: 0.9).opacity(0.35),
                        Color(red: 0.85, green: 1.0, blue: 0.9).opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size.width * 0.15
                )
            )
            .frame(width: size.width * 0.3, height: size.width * 0.3)
            .position(x: size.width * 0.9, y: size.height * 0.15)
    }
}

// MARK: - Preview

#if DEBUG
struct DecorativeShapes_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ZStack {
                Color(red: 0.1, green: 0.05, blue: 0.2)
                DecorativeShapes(theme: .neon, format: .instagramStory)
            }
            .frame(width: 200, height: 350)
            .cornerRadius(12)

            ZStack {
                Color(red: 0.2, green: 0.15, blue: 0.3)
                DecorativeShapes(theme: .gradient90s, format: .instagramStory)
            }
            .frame(width: 200, height: 350)
            .cornerRadius(12)

            ZStack {
                Color(red: 0.95, green: 0.92, blue: 0.98)
                DecorativeShapes(theme: .pastel, format: .instagramStory)
            }
            .frame(width: 200, height: 350)
            .cornerRadius(12)
        }
    }
}
#endif
