import SwiftUI

// MARK: - Glassmorphic Background

/// Clean frosted glass effect background for share cards
struct GlassmorphicBackground: View {
    let theme: ShareTheme

    private var isDark: Bool {
        theme == .glassDark
    }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle accent orbs for depth
            GeometryReader { geometry in
                ZStack {
                    // Top accent
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accentColor.opacity(isDark ? 0.15 : 0.2),
                                    theme.accentColor.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .frame(width: geometry.size.width * 0.7)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15)
                        .blur(radius: 40)

                    // Bottom accent
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    secondaryAccent.opacity(isDark ? 0.12 : 0.18),
                                    secondaryAccent.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.35
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.8)
                        .blur(radius: 30)
                }
            }

            // Subtle glass overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.03 : 0.15),
                            Color.white.opacity(isDark ? 0.01 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var secondaryAccent: Color {
        isDark
            ? Color(red: 0.5, green: 0.3, blue: 0.7)
            : Color(red: 0.7, green: 0.5, blue: 0.9)
    }
}

// MARK: - Glass Card Style

/// Modifier for applying glassmorphic card style
struct GlassCardStyle: ViewModifier {
    let isDark: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.15 : 0.4),
                                        Color.white.opacity(isDark ? 0.03 : 0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard(isDark: Bool = false) -> some View {
        modifier(GlassCardStyle(isDark: isDark))
    }
}

// MARK: - Preview

#if DEBUG
struct GlassmorphicBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GlassmorphicBackground(theme: .glassDark)
                .frame(height: 200)
                .cornerRadius(20)

            GlassmorphicBackground(theme: .glassLight)
                .frame(height: 200)
                .cornerRadius(20)
        }
        .padding()
        .background(Color.gray)
    }
}
#endif
