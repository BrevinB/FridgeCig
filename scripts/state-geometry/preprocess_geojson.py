#!/usr/bin/env python3
"""
Preprocess us-states.geojson into a Swift source file with pre-projected,
simplified state polygons. Composite layout: lower 48 fills the main viewport;
Alaska, Hawaii, and Puerto Rico are rendered in insets at the bottom-left.

Run once when regenerating geometry:
    python3 preprocess_geojson.py
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(HERE, "us-states.geojson")
OUT = os.path.join(REPO, "DietCokeTracker", "StateCans", "USStateGeometryData.swift")

# Canvas: width = 1.0, height = VIEW_ASPECT. All view rectangles below must fit
# inside [0,1] x [0, VIEW_ASPECT]. Aspect is ~1.28:1 (wider than tall) which
# matches typical US-with-insets cartograms.
VIEW_ASPECT = 0.78  # height / width

# Geographic bounds per region group. A small padding is included so coastal
# states (Maine, Florida, Washington, Texas) don't kiss the viewport edges.
LOWER48_GEO = dict(lon=(-125.5, -66.3), lat=(24.0, 49.7))
ALASKA_GEO = dict(lon=(-170.0, -130.0), lat=(51.5, 71.5))  # clip Aleutians
HAWAII_GEO = dict(lon=(-160.3, -154.7), lat=(18.9, 22.3))
PR_GEO     = dict(lon=(-67.3, -65.5), lat=(17.8, 18.6))

# Viewport rectangles per region (x0, y0, x1, y1) in normalized coords
# (x in [0,1], y in [0, VIEW_ASPECT]; y increases downward).
# Lower 48 fills the top ~75%; AK / HI / PR are insets along the bottom.
LOWER48_VIEW = (0.02, 0.02, 0.98, 0.58)
ALASKA_VIEW  = (0.02, 0.50, 0.22, 0.78)
HAWAII_VIEW  = (0.24, 0.60, 0.36, 0.78)
PR_VIEW      = (0.86, 0.66, 0.98, 0.78)

# Douglas-Peucker simplification tolerance in degrees.
SIMPLIFY_EPS = 0.04  # ~4km; plenty of detail for mobile

REGION_BY_NAME = {
    "Alaska": "AK",
    "Hawaii": "HI",
    "Puerto Rico": "PR",
}


def project(lon, lat, geo, view):
    """Equirectangular fit of geo bounds into viewport rect."""
    gx0, gx1 = geo["lon"]
    gy0, gy1 = geo["lat"]
    vx0, vy0, vx1, vy1 = view
    # Clamp to bounds (e.g. Aleutians past -180).
    lon = max(gx0, min(gx1, lon))
    lat = max(gy0, min(gy1, lat))
    # Scale x preserving a uniform scale; we want the geographic aspect preserved.
    # Simpler: non-uniform fit to rect. Acceptable for a decorative map.
    nx = (lon - gx0) / (gx1 - gx0)
    ny = (lat - gy0) / (gy1 - gy0)
    x = vx0 + nx * (vx1 - vx0)
    y = vy1 - ny * (vy1 - vy0)  # invert Y (lat grows up, y grows down)
    return (x, y)


def perp_dist_sq(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return (px - ax) ** 2 + (py - ay) ** 2
    t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    cx, cy = ax + t * dx, ay + t * dy
    return (px - cx) ** 2 + (py - cy) ** 2


def simplify(points, eps):
    if len(points) < 3:
        return points
    eps_sq = eps * eps
    keep = [False] * len(points)
    keep[0] = True
    keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        i, j = stack.pop()
        if j - i < 2:
            continue
        max_d = 0.0
        max_k = i
        a, b = points[i], points[j]
        for k in range(i + 1, j):
            d = perp_dist_sq(points[k], a, b)
            if d > max_d:
                max_d = d
                max_k = k
        if max_d > eps_sq:
            keep[max_k] = True
            stack.append((i, max_k))
            stack.append((max_k, j))
    return [p for p, k in zip(points, keep) if k]


def polygon_rings(geometry):
    """Return a flat list of rings (each ring is a list of (lon,lat) tuples)."""
    if geometry["type"] == "Polygon":
        return list(geometry["coordinates"])
    elif geometry["type"] == "MultiPolygon":
        rings = []
        for poly in geometry["coordinates"]:
            rings.extend(poly)
        return rings
    else:
        return []


def main():
    with open(SRC) as f:
        data = json.load(f)

    # Build: code -> list of projected polygons. Each polygon is a list of (x,y).
    CODES = {
        "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
        "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
        "District of Columbia": "DC", "Florida": "FL", "Georgia": "GA", "Hawaii": "HI",
        "Idaho": "ID", "Illinois": "IL", "Indiana": "IN", "Iowa": "IA",
        "Kansas": "KS", "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME",
        "Maryland": "MD", "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
        "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
        "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM",
        "New York": "NY", "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH",
        "Oklahoma": "OK", "Oregon": "OR", "Pennsylvania": "PA", "Puerto Rico": "PR",
        "Rhode Island": "RI", "South Carolina": "SC", "South Dakota": "SD", "Tennessee": "TN",
        "Texas": "TX", "Utah": "UT", "Vermont": "VT", "Virginia": "VA",
        "Washington": "WA", "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY",
    }

    out_shapes = {}  # code -> list of polygons (each polygon = [(x,y),...])

    for feat in data["features"]:
        name = feat["properties"]["name"]
        code = CODES.get(name)
        if not code:
            continue

        if name == "Alaska":
            geo, view = ALASKA_GEO, ALASKA_VIEW
        elif name == "Hawaii":
            geo, view = HAWAII_GEO, HAWAII_VIEW
        elif name == "Puerto Rico":
            geo, view = PR_GEO, PR_VIEW
        else:
            geo, view = LOWER48_GEO, LOWER48_VIEW

        polygons = []
        for ring in polygon_rings(feat["geometry"]):
            # Simplify in geographic space first.
            simplified = simplify([tuple(p[:2]) for p in ring], SIMPLIFY_EPS)
            if len(simplified) < 3:
                continue
            projected = [project(lon, lat, geo, view) for (lon, lat) in simplified]
            polygons.append(projected)

        out_shapes[code] = polygons

    # Emit Swift
    lines = []
    lines.append("// Auto-generated by preprocess_geojson.py. Do not edit by hand.")
    lines.append("import CoreGraphics")
    lines.append("")
    lines.append("enum USStateGeometryData {")
    lines.append(f"    static let viewportAspect: CGFloat = {VIEW_ASPECT}")
    lines.append("")
    lines.append("    /// code -> array of polygons (each polygon is a list of normalized CGPoints in [0,1]x[0,aspect]).")
    lines.append("    static let polygons: [String: [[CGPoint]]] = [")
    for code in sorted(out_shapes.keys()):
        polys = out_shapes[code]
        lines.append(f"        \"{code}\": [")
        for poly in polys:
            pts = ",".join(f"CGPoint(x:{x:.4f},y:{y:.4f})" for (x, y) in poly)
            lines.append(f"            [{pts}],")
        lines.append("        ],")
    lines.append("    ]")
    lines.append("}")
    lines.append("")

    with open(OUT, "w") as f:
        f.write("\n".join(lines))

    total_pts = sum(len(p) for polys in out_shapes.values() for p in polys)
    total_polys = sum(len(polys) for polys in out_shapes.values())
    print(f"Wrote {OUT}")
    print(f"States: {len(out_shapes)}  polygons: {total_polys}  points: {total_pts}")
    print(f"Output size: {os.path.getsize(OUT):,} bytes")


if __name__ == "__main__":
    main()
