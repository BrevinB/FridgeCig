import SwiftUI

struct USMapView: View {
    @EnvironmentObject var store: StateCanStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Called when the user taps a state. Receives the 2-letter code.
    var onTapState: (String) -> Void = { _ in }
    /// Optional code to highlight (e.g. most recently interacted-with state).
    var highlightedCode: String? = nil

    // Zoom / pan state. `scale` and `offset` are committed values; the gesture
    // values are added on top while a gesture is in progress.
    @State private var scale: CGFloat = 1.0
    @State private var gestureScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var gestureOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    private var totalScale: CGFloat { scale * gestureScale }
    private var totalOffset: CGSize {
        CGSize(width: offset.width + gestureOffset.width,
               height: offset.height + gestureOffset.height)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.25)
    }

    private var uncollectedFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    private func fillColor(for code: String) -> Color {
        store.isCollected(code) ? themeManager.primaryColor : uncollectedFill
    }

    var body: some View {
        GeometryReader { proxy in
            let baseSize = CGSize(
                width: proxy.size.width,
                height: proxy.size.width * USStateGeometry.viewportAspect
            )

            ZStack {
                Canvas { context, _ in
                    for code in USStateGeometry.codes {
                        let path = USStateGeometry.path(for: code, in: baseSize)
                        context.fill(path, with: .color(fillColor(for: code)))
                        context.stroke(path, with: .color(strokeColor), lineWidth: 0.6 / max(totalScale, 1))

                        if highlightedCode == code {
                            context.stroke(path,
                                           with: .color(themeManager.primaryColor),
                                           lineWidth: 2.0 / max(totalScale, 1))
                        }
                    }

                    // Photo-verified indicators on top of the map fill.
                    let dotRadius: CGFloat = 4.0 / max(totalScale, 1)
                    let ringWidth: CGFloat = 1.5 / max(totalScale, 1)
                    for code in USStateGeometry.codes where store.isVerified(code) {
                        guard let centroid = USStateGeometry.centroid(for: code, in: baseSize) else { continue }
                        let dotRect = CGRect(
                            x: centroid.x - dotRadius,
                            y: centroid.y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        let dotPath = Path(ellipseIn: dotRect)
                        context.fill(dotPath, with: .color(.white))
                        context.stroke(dotPath, with: .color(themeManager.primaryColor), lineWidth: ringWidth)
                    }
                }
                .frame(width: baseSize.width, height: baseSize.height)
            }
            .scaleEffect(totalScale, anchor: .center)
            .offset(totalOffset)
            .frame(width: baseSize.width, height: baseSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    magnifyGesture(baseSize: baseSize),
                    panGesture(baseSize: baseSize)
                )
            )
            .onTapGesture(count: 2) {
                resetZoom()
            }
            .onTapGesture(coordinateSpace: .local) { location in
                handleTap(location: location, baseSize: baseSize)
            }
        }
        .aspectRatio(1.0 / USStateGeometry.viewportAspect, contentMode: .fit)
    }

    // MARK: - Gestures

    private func magnifyGesture(baseSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                gestureScale = value.magnification
            }
            .onEnded { value in
                let newScale = (scale * value.magnification).clamped(to: minScale...maxScale)
                scale = newScale
                gestureScale = 1.0
                offset = clampOffset(offset, scale: newScale, baseSize: baseSize)
                if newScale == 1.0 { offset = .zero }
            }
    }

    private func panGesture(baseSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                // Only pan if zoomed in. Otherwise let tap gestures win.
                guard totalScale > 1.001 else { return }
                gestureOffset = value.translation
            }
            .onEnded { value in
                guard scale > 1.001 else {
                    gestureOffset = .zero
                    return
                }
                let proposed = CGSize(width: offset.width + value.translation.width,
                                      height: offset.height + value.translation.height)
                offset = clampOffset(proposed, scale: scale, baseSize: baseSize)
                gestureOffset = .zero
            }
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            scale = 1.0
            offset = .zero
            gestureScale = 1.0
            gestureOffset = .zero
        }
        HapticManager.lightImpact()
    }

    private func clampOffset(_ proposed: CGSize, scale: CGFloat, baseSize: CGSize) -> CGSize {
        guard scale > 1 else { return .zero }
        let scaledExtraW = baseSize.width * (scale - 1) / 2
        let scaledExtraH = baseSize.height * (scale - 1) / 2
        return CGSize(
            width: min(max(proposed.width, -scaledExtraW), scaledExtraW),
            height: min(max(proposed.height, -scaledExtraH), scaledExtraH)
        )
    }

    // MARK: - Hit testing

    /// Convert a tap location in the visible (post-transform) coordinate space
    /// back into the underlying map's coordinate space, then hit-test.
    private func handleTap(location: CGPoint, baseSize: CGSize) {
        let center = CGPoint(x: baseSize.width / 2, y: baseSize.height / 2)
        let mapPoint = CGPoint(
            x: (location.x - totalOffset.width - center.x) / totalScale + center.x,
            y: (location.y - totalOffset.height - center.y) / totalScale + center.y
        )
        if let code = USStateGeometry.hitTest(mapPoint, in: baseSize) {
            HapticManager.lightImpact()
            onTapState(code)
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
