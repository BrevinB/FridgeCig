import SwiftUI
import CoreGraphics

/// Runtime helpers over the pre-baked `USStateGeometryData`.
/// Data is normalized to a viewport with width = 1 and height = `viewportAspect`.
enum USStateGeometry {
    static var viewportAspect: CGFloat { USStateGeometryData.viewportAspect }

    /// All state codes that have geometry data, in alphabetical order.
    static let codes: [String] = USStateGeometryData.polygons.keys.sorted()

    /// Build a SwiftUI Path for a state, scaled into the given size.
    /// The geometry data assumes width = 1 and height = viewportAspect,
    /// so the scale is `size.width`; height should be `size.width * viewportAspect`.
    static func path(for code: String, in size: CGSize) -> Path {
        guard let polygons = USStateGeometryData.polygons[code] else { return Path() }
        var path = Path()
        let sx = size.width
        let sy = size.width   // uniform scale so aspect is preserved
        for polygon in polygons {
            guard let first = polygon.first else { continue }
            path.move(to: CGPoint(x: first.x * sx, y: first.y * sy))
            for i in 1..<polygon.count {
                let p = polygon[i]
                path.addLine(to: CGPoint(x: p.x * sx, y: p.y * sy))
            }
            path.closeSubpath()
        }
        return path
    }

    /// Returns the centroid of the state's largest polygon, scaled into `size`.
    /// Useful for placing a label or indicator over the state.
    static func centroid(for code: String, in size: CGSize) -> CGPoint? {
        guard let normalized = normalizedCentroids[code] else { return nil }
        return CGPoint(x: normalized.x * size.width, y: normalized.y * size.width)
    }

    /// Centroid of each state's largest polygon, in normalized space.
    private static let normalizedCentroids: [String: CGPoint] = {
        var result: [String: CGPoint] = [:]
        for (code, polygons) in USStateGeometryData.polygons {
            guard let largest = polygons.max(by: { $0.count < $1.count }), !largest.isEmpty else { continue }
            var sx: CGFloat = 0
            var sy: CGFloat = 0
            for p in largest {
                sx += p.x
                sy += p.y
            }
            result[code] = CGPoint(x: sx / CGFloat(largest.count), y: sy / CGFloat(largest.count))
        }
        return result
    }()

    /// Returns the state code whose polygon contains the given point.
    /// Uses even-odd winding; iterates all polygons.
    static func hitTest(_ point: CGPoint, in size: CGSize) -> String? {
        let nx = point.x / size.width
        let ny = point.y / size.width
        let target = CGPoint(x: nx, y: ny)
        // Iterate in reverse alphabetical for no particular reason — order rarely matters
        // because polygons don't overlap. We pick the first hit.
        for code in codes {
            if let polygons = USStateGeometryData.polygons[code] {
                for polygon in polygons where pointInPolygon(target, polygon: polygon) {
                    return code
                }
            }
        }
        return nil
    }

    private static func pointInPolygon(_ p: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let a = polygon[i]
            let b = polygon[j]
            if ((a.y > p.y) != (b.y > p.y)) {
                let slope = (p.y - a.y) / (b.y - a.y)
                let xIntersect = a.x + slope * (b.x - a.x)
                if p.x < xIntersect {
                    inside.toggle()
                }
            }
            j = i
        }
        return inside
    }
}
