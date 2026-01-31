import SwiftUI

// MARK: - Bubble Model

struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
}

// MARK: - Fizz Bubbles View

struct FizzBubblesView: View {
    let bubbleCount: Int
    let isAnimating: Bool

    @State private var bubbles: [Bubble] = []

    init(bubbleCount: Int = 20, isAnimating: Bool = true) {
        self.bubbleCount = bubbleCount
        self.isAnimating = isAnimating
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.dietCokeFizzBlue.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: bubble.size / 2
                            )
                        )
                        .frame(width: bubble.size, height: bubble.size)
                        .position(x: bubble.x, y: bubble.y)
                        .opacity(bubble.opacity)
                }
            }
            .onAppear {
                initializeBubbles(in: geometry.size)
                if isAnimating {
                    startAnimation(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func initializeBubbles(in size: CGSize) {
        bubbles = (0..<bubbleCount).map { _ in
            Bubble(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 3...12),
                opacity: Double.random(in: 0.2...0.6),
                speed: Double.random(in: 1.5...4.0)
            )
        }
    }

    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                for i in bubbles.indices {
                    bubbles[i].y -= bubbles[i].speed

                    // Add slight horizontal wobble
                    bubbles[i].x += CGFloat.random(in: -0.5...0.5)

                    // Reset bubble when it goes off screen
                    if bubbles[i].y < -20 {
                        bubbles[i].y = size.height + 20
                        bubbles[i].x = CGFloat.random(in: 0...size.width)
                        bubbles[i].size = CGFloat.random(in: 3...12)
                        bubbles[i].opacity = Double.random(in: 0.2...0.6)
                    }
                }
            }
        }
    }
}

// MARK: - Celebration Fizz Burst

struct FizzBurstView: View {
    @Binding var isActive: Bool
    @State private var particles: [FizzParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    createBurst(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createBurst(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        particles = (0..<30).map { _ in
            let angle = Double.random(in: 0...2 * .pi)
            let velocity = Double.random(in: 100...300)
            return FizzParticle(
                position: center,
                velocity: CGVector(dx: cos(angle) * velocity, dy: sin(angle) * velocity),
                size: CGFloat.random(in: 4...12),
                color: [Color.dietCokeRed, Color.white, Color.dietCokeFizzBlue].randomElement()!,
                opacity: 1.0
            )
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.6)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.dx * 0.6
                particles[i].position.y += particles[i].velocity.dy * 0.6
                particles[i].opacity = 0
            }
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isActive = false
            particles = []
        }
    }
}

struct FizzParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Ambient Bubble Background

struct AmbientBubblesBackground: View {
    @State private var bubbles: [AmbientBubble] = []
    let bubbleCount: Int

    init(bubbleCount: Int = 15) {
        self.bubbleCount = bubbleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.dietCokeIceBlue.opacity(0.2),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: bubble.size
                            )
                        )
                        .frame(width: bubble.size, height: bubble.size)
                        .position(x: bubble.x, y: bubble.y)
                        .opacity(bubble.opacity)
                }
            }
            .onAppear {
                initializeBubbles(in: geometry.size)
                animateBubbles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func initializeBubbles(in size: CGSize) {
        bubbles = (0..<bubbleCount).map { _ in
            AmbientBubble(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.5...size.height * 1.2),
                size: CGFloat.random(in: 8...24),
                opacity: Double.random(in: 0.15...0.35),
                duration: Double.random(in: 4...8)
            )
        }
    }

    private func animateBubbles(in size: CGSize) {
        for i in bubbles.indices {
            let delay = Double.random(in: 0...2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateSingleBubble(index: i, in: size)
            }
        }
    }

    private func animateSingleBubble(index: Int, in size: CGSize) {
        guard index < bubbles.count else { return }

        withAnimation(.easeInOut(duration: bubbles[index].duration).repeatForever(autoreverses: false)) {
            bubbles[index].y = -bubbles[index].size
        }
    }
}

struct AmbientBubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var duration: Double
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: phase * geometry.size.width * 1.5 - geometry.size.width * 0.25)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.dietCokeCardBackground
            .ignoresSafeArea()

        FizzBubblesView(bubbleCount: 25)
    }
}
