"""Draws the app's illustrations and bakes them into Dart data.

Run from `app/`:  python3 -I tool/art/generate.py

Scenes are written as small SVG-like paths, roughened by `handdrawn.py`, then flattened into polygons so the app can
paint them itself (no SVG package) and colour them per theme. Colours are named roles here; their values live in
`lib/shared/brand/art/art_palette.dart`.
"""
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import handdrawn as hd  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "lib", "shared", "brand", "art", "art_data.g.dart")

# Placeholder colours that stand for roles while drawing; each must be unique.
ROLES = ["ink", "paper", "card", "snow", "rock", "rockShade", "sage", "forest", "forestShade", "lake", "lakeShade", "sun",
         "sunShade", "accent", "sand", "tent", "tentShade", "glow", "skyTop", "skyMid", "skyLow", "rangeFar", "peak",
         "peakShade", "hillBack", "hillFront", "pine", "pineShade", "wood", "metal", "ground", "meadowFar", "meadow"]
C = {name: f"#0000{i + 1:02x}" for i, name in enumerate(ROLES)}
BY_HEX = {v: k for k, v in C.items()}

W = 3.2
INK = C["ink"]


# ------------------------------------------------------------------ drawing primitives (SVG fragments)

def path(d, fill="none", stroke=INK, w=W, dash=None):
    o = ""
    if fill != "none":
        o += hd.wash(d, fill, under=C["paper"])
    if stroke:
        o += hd.ink(d, stroke, w * 1.08, f'stroke-dasharray="{dash}"' if dash else "")
    return o


def blob(d, fill, op=1):
    return hd.wash(d, fill, op, under=fill)


def circle(x, y, r, fill="none", stroke=INK, w=W):
    if r < 4 and not stroke:
        return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>'
    return path(hd.circle_path(x, y, r), fill, stroke, w)


def at(x, y, body, s=1):
    return f'<g transform="translate({x},{y}) scale({s})">{body}</g>'


def sun(x, y, r=24):
    rays = ""
    for dx, dy in [(0, -1), (.71, -.71), (1, 0), (.71, .71), (0, 1), (-.71, .71), (-1, 0), (-.71, -.71)]:
        rays += path(f"M{x + dx * (r + 8)} {y + dy * (r + 8)} L{x + dx * (r + 15)} {y + dy * (r + 15)}", w=2.8)
    shade = f"M{x + r * .82} {y - r * .4} Q{x + r * 1.2} {y + r * .9} {x - r * .4} {y + r * .85} Q{x + r * .65} {y + r * .7} {x + r * .82} {y - r * .4} Z"
    return circle(x, y, r, C["sun"], None) + blob(shade, C["sunShade"]) + circle(x, y, r) + rays


def cloud(x, y, s=1):
    return at(x, y, path("M-34 12 C-48 12 -48 -8 -31 -8 C-30 -27 0 -32 7 -14 C18 -24 37 -15 33 -2 C46 -1 45 12 33 12 Z",
                         C["snow"], INK, 3 / s)
              + path("M-56 12 H-48 M44 12 H60 M-20 21 H8", w=2.6 / s), s)


def bird(x, y, s=1):
    return at(x, y, path("M-12 0 Q-6 -8 0 0 Q6 -8 12 0", w=2.6 / s), s)


def pine(x, y, s=1):
    d = "M0 -62 L15 -38 H8 L22 -18 H13 L27 3 H-27 L-13 -18 H-22 L-8 -38 H-15 Z"
    return at(x, y, path("M0 3 V14", w=W / s) + blob(d, C["pine"])
              + blob("M0 -62 L15 -38 H8 L22 -18 H13 L27 3 H4 Z", C["pineShade"]) + path(d, w=W / s), s)


def tree(x, y, s=1, fill="sage"):
    return at(x, y, blob("M-4 -62 C17 -66 31 -46 25 -30 C37 -14 20 2 3 -4 C-17 6 -34 -12 -24 -28 C-31 -46 -20 -60 -4 -62 Z", C[fill])
              + path("M-6 -58 C14 -63 28 -44 22 -28 C33 -13 17 0 0 -6 C-18 3 -32 -12 -23 -27 C-30 -43 -22 -55 -12 -57", w=W / s)
              + path("M0 14 V-34 M0 -18 L11 -28 M0 -8 L-10 -18", w=2.8 / s), s)


def hill(d, fill):
    """A filled landform whose ink follows only its ridge (the part before the first V)."""
    return blob(d, C[fill]) + path(d.split(" V")[0], w=2.4)


def hill(d, fill):
    """A filled landform whose ink follows only its ridge (the part before the first V)."""
    return blob(d, C[fill]) + path(d.split(" V")[0], w=2.4)


# ------------------------------------------------------------------ the mark: a trail cairn before the summit
# 400 x 400 artwork. Sky and land bleed to -110..510 for Android's adaptive icon, which shows more around the edges.

def mark_sky():
    return (f'<rect x="-110" y="-110" width="620" height="620" fill="{C["skyTop"]}"/>'
            + hd.wash("M-120 186 C-60 210 20 160 90 150 C190 130 260 214 420 170 C460 164 490 180 520 172 V520 H-120 Z", C["skyMid"], .9))


def mark_sun():
    return sun(88, 100, 30)


def mark_peak():
    peak = "M70 292 L236 106 Q252 88 268 106 L430 292 V420 H70 Z"
    return (blob(peak, C["peak"]) + blob("M252 96 Q262 96 268 106 L430 292 V420 H330 L276 192 Z", C["peakShade"])
            + blob("M200 146 L236 106 Q252 88 268 106 L306 150 L282 140 L264 166 L246 134 L226 162 L216 142 Z", C["snow"])
            + path("M200 146 L216 142 L226 162 L246 134 L264 166 L282 140 L306 150", w=5)
            + path("M70 292 L236 106 Q252 88 268 106 L430 292", w=7))


def mark_ground():
    ridge = "M-120 330 C-60 322 -10 310 20 296 C90 276 170 330 270 304 C330 290 400 300 520 276"
    return blob(ridge + " V520 H-120 Z", C["ground"]) + path(ridge, w=7)


def stone(cx, cy, rx, ry, role):
    d = (f"M{cx - rx} {cy} C{cx - rx} {cy - ry * 1.25} {cx + rx * .9} {cy - ry * 1.35} {cx + rx} {cy - ry * .1} "
         f"C{cx + rx * 1.05} {cy + ry * 1.2} {cx - rx * .95} {cy + ry * 1.25} {cx - rx} {cy} Z")
    return (path(d, C[role], w=7)
            + path(f"M{cx - rx * .55} {cy - ry * .35} Q{cx - rx * .25} {cy - ry * .65} {cx + rx * .05} {cy - ry * .62}",
                   stroke=C["snow"], w=5))


def mark_stone1():
    return stone(138, 326, 76, 28, "sand")


def mark_stone2():
    return stone(142, 278, 58, 24, "rock")


def mark_stone3():
    return stone(134, 236, 43, 21, "sand")


def mark_stone4():
    return stone(140, 200, 28, 17, "accent")


# bottom to top, the order the opening animation stacks them
MARK = [mark_sky, mark_sun, mark_peak, mark_ground, mark_stone1, mark_stone2, mark_stone3, mark_stone4]


# ------------------------------------------------------------------ baking

def simplify(pts, eps=.2):
    """Ramer-Douglas-Peucker: drops points that do not change the outline."""
    if len(pts) < 3:
        return pts
    (ax, ay), (bx, by) = pts[0], pts[-1]
    length = math.hypot(bx - ax, by - ay)
    best, index = -1.0, 0
    for i in range(1, len(pts) - 1):
        px, py = pts[i]
        d = (abs((bx - ax) * (ay - py) - (ax - px) * (by - ay)) / length) if length > 1e-6 else math.hypot(px - ax, py - ay)
        if d > best:
            best, index = d, i
    if best <= eps:
        return [pts[0], pts[-1]]
    return simplify(pts[: index + 1], eps)[:-1] + simplify(pts[index:], eps)


def rings_of(d):
    """Polygons of the `M x y L ... Z` paths that handdrawn.py writes."""
    out = []
    for part in d.split("M")[1:]:
        nums = [float(v) for v in re.findall(r"-?\d+(?:\.\d+)?", part)]
        out.append((list(zip(nums[0::2], nums[1::2])), "Z" in part))
    return out


def dashes(pts, on, off):
    out, current, left, drawing = [], [pts[0]], on, True
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        seg = math.hypot(bx - ax, by - ay)
        done = 0.0
        while seg - done > left:
            done += left
            p = (ax + (bx - ax) * done / seg, ay + (by - ay) * done / seg)
            if drawing:
                out.append(current + [p])
            drawing = not drawing
            left = on if drawing else off
            current = [p]
        left -= seg - done
        current.append((bx, by))
    if drawing and len(current) > 1:
        out.append(current)
    return out


class Drawing:
    def __init__(self):
        self.ops, self.clips = [], []

    def bake(self, fragment):
        root = ET.fromstring(f"<svg>{fragment}</svg>")
        self.defs = {}
        self.walk(root, (0.0, 0.0, 1.0), 1.0, -1)
        return self

    def walk(self, node, tf, alpha, clip):
        tx, ty, s = tf

        def move(pts):
            return [(tx + x * s, ty + y * s) for x, y in pts]

        for el in node:
            a = el.attrib
            op = alpha * float(a.get("opacity", 1))
            if el.tag == "g":
                inner, inner_clip = tf, clip
                m = re.match(r"translate\(([-\d.]+),([-\d.]+)\) scale\(([-\d.]+)\)", a.get("transform", ""))
                if m:
                    x, y, k = (float(v) for v in m.groups())
                    inner = (tx + x * s, ty + y * s, s * k)
                ref = re.match(r"url\(#(\w+)\)", a.get("clip-path", ""))
                if ref:
                    inner_clip = len(self.clips)
                    self.clips.append(move(self.defs[ref.group(1)]))
                self.walk(el, inner, op, inner_clip)
            elif el.tag == "clipPath":
                self.defs[a["id"]] = simplify(rings_of(el[0].attrib["d"])[0][0])
            elif el.tag == "rect":
                x, y, w, h = (float(a[k]) for k in ("x", "y", "width", "height"))
                self.add(a["fill"], [move([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])], op, clip)
            elif el.tag == "circle":
                cx, cy, r = float(a["cx"]), float(a["cy"]), float(a["r"])
                n = max(8, int(r * s * 3))
                ring = [(cx + r * math.cos(6.2832 * i / n), cy + r * math.sin(6.2832 * i / n)) for i in range(n)]
                self.add(a["fill"], [move(ring)], op, clip)
            elif el.tag == "ellipse":
                x, y = move([(float(a["cx"]), float(a["cy"]))])[0]
                angle = float(re.match(r"rotate\((-?\d+)", a["transform"]).group(1))
                role = "bloomDark" if "dark" in a["fill"] else "bloomLight"
                self.ops.append(dict(role=role, bloom=[x, y, float(a["rx"]) * s, float(a["ry"]) * s, math.radians(angle)],
                                     alpha=op, clip=clip))
            elif el.tag == "path":
                rings = rings_of(a["d"])
                if a.get("fill", "none") != "none":
                    shapes = [move(simplify(p)) for p, _ in rings]
                    self.add(a["fill"], shapes, op, clip)
                if "stroke" in a:
                    width = float(a["stroke-width"]) * s
                    lines = []
                    for pts, closed in rings:
                        pts = pts + pts[:1] if closed else pts
                        if "stroke-dasharray" in a:
                            on, off = (float(v) for v in a["stroke-dasharray"].split())
                            lines += [move(simplify(d)) for d in dashes(pts, on, off)]
                        else:
                            lines.append(move(simplify(pts)))
                    # the pooled edge of a wash uses a fixed brown, which follows the ink role
                    self.add(a["stroke"], lines, op, clip, width)

    def add(self, colour, rings, alpha, clip, stroke=0.0):
        role = BY_HEX.get(colour) or {"#4a3526": "edge", "#fffaf0": "bloomLight"}[colour]
        self.ops.append(dict(role=role, rings=rings, alpha=alpha, clip=clip, stroke=stroke))


def num(v):
    return f"{v:.1f}".removesuffix(".0")


def flat(pts):
    return "[" + ",".join(f"{num(x)},{num(y)}" for x, y in pts) + "]"


def dart(name, drawing):
    ops = []
    for o in drawing.ops:
        fields = [f"ArtColor.{o['role']}"]
        if "bloom" in o:
            b = o["bloom"]
            fields.append("bloom: [" + ",".join(f"{v:.2f}" for v in b) + "]")
        else:
            fields.append("rings: [" + ",".join(flat(r) for r in o["rings"]) + "]")
            if o["stroke"]:
                fields.append(f"stroke: {o['stroke']:.2f}")
        if o["alpha"] < .999:
            fields.append(f"alpha: {o['alpha']:.2f}")
        if o["clip"] >= 0:
            fields.append(f"clip: {o['clip']}")
        ops.append(f"  ArtOp({', '.join(fields)}),")
    clips = ",".join(flat(c) for c in drawing.clips)
    return f"const {name} = ArtDrawing(clips: [{clips}], ops: [\n" + "\n".join(ops) + "\n]);\n"


def draw(fn):
    # every drawing starts from its own seed, so editing one leaves the others unchanged
    hd.rng.seed(fn.__name__)
    return Drawing().bake(fn())


def main():
    hd.CALM = .5
    parts = []
    parts += [(f"_{fn.__name__.replace('_s', 'S').replace('_p', 'P').replace('_g', 'G')}", fn) for fn in MARK]
    out = ["// GENERATED by tool/art/generate.py - do not edit.", "// dart format off", "// ignore_for_file: type=lint", "",
           "import 'art_model.dart';", ""]
    out += [dart(name, draw(fn)) for name, fn in parts]
    out.append("const artMark = [_markSky, _markSun, _markPeak, _markGround, _markStone1, _markStone2, _markStone3, _markStone4];")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"{os.path.normpath(OUT)}: {os.path.getsize(OUT) // 1024} KB")


if __name__ == "__main__":
    main()
