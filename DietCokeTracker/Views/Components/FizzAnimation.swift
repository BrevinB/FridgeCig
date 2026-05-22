import SwiftUI

// MARK: - Bubble Seed

/// Immutable seed for a fizz bubble. Position is computed each frame as a
/// pure function of elapsed time, so the Canvas renderer never mutates state.
struct BubbleSeed: Identifiable {
    let id = UUID()
    let xBase: CGFloat
    let yStart: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double      // pixels per timer tick (legacy units)
    let wobblePhase: Double
}

// MARK: - Fizz Bubbles View

struct FizzBubblesView: View {
    let bubbleCount: Int
    let isAnimating: Bool

    @State private var bubbles: [BubbleSeed] = []
    @State private var startDate = Date()

    init(bubbleCount: Int = 20, isAnimating: Bool = true) {
        self.bubbleCount = bubbleCount
        self.isAnimating = isAnimating
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimating)) { context in
                Canvas { canvasContext, size in
                    let elapsed = context.date.timeIntervalSince(startDate)
                    for bubble in bubbles {
                        let position = computePosition(bubble: bubble, elapsed: elapsed, in: size)
                        let rect = CGRect(
                            x: position.x - bubble.size / 2,
                            y: position.y - bubble.size / 2,
                            width: bubble.size,
                            height: bubble.size
                        )
                        let gradient = Gradient(colors: [
                            Color.white.opacity(0.8 * bubble.opacity),
                            Color.dietCokeFizzBlue.opacity(0.3 * bubble.opacity),
                            Color.clear
                        ])
                        canvasContext.fill(
                            Path(ellipseIn: rect),
                            with: .radialGradient(
                                gradient,
                                center: CGPoint(x: rect.midX, y: rect.midY),
                                startRadius: 0,
                                endRadius: bubble.size / 2
                            )
                        )
                    }
                }
            }
            .onAppear {
                if bubbles.isEmpty {
                    bubbles = (0..<bubbleCount).map { _ in
                        BubbleSeed(
                            xBase: CGFloat.random(in: 0...geometry.size.width),
                            yStart: CGFloat.random(in: 0...geometry.size.height),
                            size: CGFloat.random(in: 3...12),
                            opacity: Double.random(in: 0.2...0.6),
                            speed: Double.random(in: 1.5...4.0),
                            wobblePhase: Double.random(in: 0...(2 * .pi))
                        )
                    }
                    startDate = Date()
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Pure function: legacy code moved `speed` pixels per 0.05s tick. Preserve
    /// the same visual cadence by converting that to pixels/sec.
    private func computePosition(bubble: BubbleSeed, elapsed: TimeInterval, in size: CGSize) -> CGPoint {
        let pixelsPerSecond = bubble.speed / 0.05
        let travel = pixelsPerSecond * elapsed
        // Total wrap range: from yStart up to -20, then jumps to height+20.
        let range = size.height + 40
        let wrapped = travel.truncatingRemainder(dividingBy: range)
        var y = bubble.yStart - CGFloat(wrapped)
        if y < -20 { y += range }
        let wobble = sin(elapsed * 2 + bubble.wobblePhase) * 4
        return CGPoint(x: bubble.xBase + CGFloat(wobble), y: y)
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
