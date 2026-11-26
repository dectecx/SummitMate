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


# ------------------------------------------------------------------ small pictures (-40..40 on both axes)

def icon_map():
    return (path("M-31 -20 L-11 -28 L11 -19 L31 -27 V20 L11 28 L-11 19 L-31 27 Z", C["sand"]) + path("M-11 -28 V19 M11 -19 V28", w=2.4)
            + path("M-23 12 C-14 -8 0 18 18 -8", stroke=C["accent"], w=2.8, dash="5 6") + circle(20, -11, 4, C["accent"], w=2.4))


def icon_tent():
    return (path("M-32 24 L0 -24 L32 24 Z", C["tent"]) + path("M-12 24 L0 -2 L12 24 Z", C["wood"])
            + path("M0 -24 L-5 -32 M0 -24 L6 -31 M-38 24 H24 M31 24 H38"))


def icon_summit():
    return (path("M-34 26 L-4 -18 L26 26 Z", C["rock"]) + path("M-15 -2 L-4 -18 L7 -2 L1 -4 L-3 3 L-9 -4 Z", C["snow"], w=2.6)
            + path("M-4 -18 V-34") + path("M-3 -34 L15 -29 L-3 -22 Z", C["accent"]) + path("M-38 26 H18 M26 26 H38"))


def icon_water():
    return (path("M-9 -32 H9 V-24 H-9 Z", C["accent"])
            + path("M-9 -24 C-9 -18 -17 -18 -17 -8 V26 Q-17 31 -12 31 H12 Q17 31 17 26 V-8 C17 -18 9 -18 9 -24 Z", C["lake"])
            + path("M-17 2 H17 M-17 17 H17", w=2.6) + path("M-10 -9 V-4", stroke=C["snow"], w=3.4))


def icon_sleep():
    return (path("M-30 -6 C-30 -22 -10 -24 -8 -10 L26 -8 Q34 -6 34 6 V14 Q34 22 26 22 H-22 Q-32 22 -32 10 Z", C["sage"])
            + path("M-8 -10 C-4 2 -6 12 -10 22 M8 -9 C12 2 10 12 6 22", w=2.4) + circle(-19, -5, 8, C["sand"], w=2.4))


def icon_cook():
    return (path("M-22 12 Q-22 7 -15 7 H15 Q22 7 22 12 V26 Q22 31 16 31 H-16 Q-22 31 -22 26 Z", C["lake"])
            + path("M-6 7 V-2 H6 V7", C["metal"]) + path("M-6 1 L-22 -6 V-14 M6 1 L22 -6 V-14")
            + path("M0 -32 C2 -23 11 -20 8 -12 C6 -6 -6 -6 -8 -12 C-9 -19 -2 -21 0 -32 Z", C["accent"])
            + path("M-13 18 H-1", stroke=C["snow"], w=3))


def icon_jacket():
    return (path("M-12 -28 L-30 -16 L-36 12 L-24 16 L-20 0 V30 H20 V0 L24 16 L36 12 L30 -16 L12 -28 Q0 -18 -12 -28 Z", C["accent"])
            + path("M0 -21 V30", w=2.4) + path("M-13 12 H-6 M6 12 H13", w=2.6))


def icon_backpack():
    return (path("M-12 -22 C-12 -36 12 -36 12 -22") + path("M-22 28 V-8 C-22 -30 22 -30 22 -8 V28 Q22 32 18 32 H-18 Q-22 32 -22 28 Z", C["sage"])
            + path("M-14 6 H14 V22 Q14 26 10 26 H-10 Q-14 26 -14 22 Z", C["sand"]) + path("M-5 6 V14 H5 V6 M-22 -6 H-6 M3 -6 H22", w=2.6))


def icon_headlamp():
    strap = "M-18 -2 C-34 -6 -34 -24 0 -24 C34 -24 34 -6 18 -2"
    return (path(strap, w=9) + path(strap, stroke=C["accent"], w=3.4)
            + path("M-18 -12 H18 Q22 -12 22 -8 V8 Q22 12 18 12 H-18 Q-22 12 -22 8 V-8 Q-22 -12 -18 -12 Z", C["metal"])
            + circle(0, 0, 8, C["glow"]) + path("M-14 20 L-19 30 M0 21 V32 M14 20 L19 30", w=2.8))


def icon_firstAid():
    return (path("M-10 -16 V-26 H10 V-16") + path("M-30 -16 H30 Q34 -16 34 -12 V24 Q34 28 30 28 H-30 Q-34 28 -34 24 V-12 Q-34 -16 -30 -16 Z", C["accent"])
            + path("M-5 -6 H5 V1 H12 V11 H5 V18 H-5 V11 H-12 V1 H-5 Z", C["snow"], w=2.2))


def icon_compass():
    return (circle(0, 3, 28, C["sand"]) + circle(0, 3, 19, C["snow"]) + path("M0 -25 V-32 M-4 -32 H4")
            + path("M10 -7 L4 7 L-4 -1 Z", C["accent"], w=2.4) + path("M-10 13 L4 7 L-4 -1 Z", C["metal"], w=2.4))


def icon_forest():
    return pine(-16, 20, .78) + pine(18, 22, .62) + path("M-36 28 H18 M26 28 H36")


ICONS = {"map": icon_map, "tent": icon_tent, "summit": icon_summit, "water": icon_water, "sleep": icon_sleep,
         "cook": icon_cook, "jacket": icon_jacket, "backpack": icon_backpack, "headlamp": icon_headlamp,
         "firstAid": icon_firstAid, "compass": icon_compass, "forest": icon_forest}


# ------------------------------------------------------------------ empty screens (160 x 120, centred on 0,0)

def backdrop(role="sage"):
    return hd.wash("M-66 34 C-84 -6 -44 -50 -4 -46 C34 -62 84 -26 68 12 C78 44 28 52 -4 46 C-34 54 -62 52 -66 34 Z", C[role], .32)


def floor(y=40):
    return path(f"M-70 {y} H34 M44 {y} H70", w=2.4) + path(f"M-46 {y + 9} h18 M10 {y + 11} h26", w=1.8)


def placed(icon, x=0, y=0, s=1.0):
    return at(x, y, icon(), s)


def spark(x, y, s=.7):
    return at(x, y, path("M0 -11 Q2 -2 11 0 Q2 2 0 11 Q-2 2 -11 0 Q-2 -2 0 -11 Z", C["sun"], INK, 2 / s), s)


def bubble(x, y, w, h, fill, tail):
    d = (f"M{x + 10} {y} H{x + w - 10} Q{x + w} {y} {x + w} {y + 10} V{y + h - 10} Q{x + w} {y + h} {x + w - 10} {y + h} "
         f"H{x + 22} L{x + 10} {y + h + 10} L{x + 12} {y + h} H{x + 10} Q{x} {y + h} {x} {y + h - 10} V{y + 10} Q{x} {y} {x + 10} {y} Z")
    if tail == "right":
        d = (f"M{x + 10} {y} H{x + w - 10} Q{x + w} {y} {x + w} {y + 10} V{y + h - 10} Q{x + w} {y + h} {x + w - 10} {y + h} "
             f"H{x + w - 12} L{x + w - 10} {y + h + 10} L{x + w - 22} {y + h} H{x + 10} Q{x} {y + h} {x} {y + h - 10} V{y + 10} Q{x} {y} {x + 10} {y} Z")
    return path(d, C[fill], w=2.6)


def person(x, y, fill, s=1.0):
    return at(x, y, path("M-16 24 C-16 -4 16 -4 16 24 Z", C[fill], w=2.6 / s) + circle(0, -14, 11, C["sand"], w=2.6 / s), s)


def scene_trip():
    return (backdrop() + at(34, -26, sun(0, 0, 9)) + at(-12, 14, path("M-48 26 L-10 -34 L30 26 Z", C["rock"])
            + blob("M-20 -18 L-10 -34 L1 -18 L-5 -20 L-9 -13 L-15 -20 Z", C["snow"]) + path("M-20 -18 L-15 -20 L-9 -13 L-5 -20 L1 -18", w=2.2))
            + placed(icon_tent, 34, 20, .78) + pine(-56, 36, .55) + floor())


def scene_gear():
    return backdrop("sand") + placed(icon_backpack, -8, 2, 1.15) + placed(icon_water, 36, 14, .8) + spark(-46, -22) + floor()


def scene_meal():
    steam = "".join(path(f"M{x} -16 C{x - 8} -24 {x + 8} -28 {x} -38", w=2.4) for x in (-14, 2, 18))
    pot = (path("M-34 -6 H38 V22 Q38 36 24 36 H-20 Q-34 36 -34 22 Z", C["lake"]) + path("M-40 -6 H44", w=5)
           + path("M-34 6 H-46 M38 6 H50", w=4) + path("M-22 6 V18", stroke=C["snow"], w=3.4))
    return backdrop("lake") + steam + pot + floor()


def scene_chat():
    dots = "".join(circle(x, -16, 3, C["ink"], None) for x in (-38, -24, -10))
    return backdrop() + bubble(-58, -38, 68, 40, "snow", "left") + dots + bubble(-6, -6, 66, 36, "sage", "right") + \
        path("M10 8 H44 M10 17 H32", w=2.4) + floor(46)


def scene_map():
    return backdrop("lake") + placed(icon_map, -4, 4, 1.5) + placed(icon_compass, 44, 22, .62) + floor(46)


def scene_friends():
    return backdrop("sand") + person(-26, 12, "accent", 1.05) + person(26, 14, "lake") + person(0, 2, "sage", 1.2) + spark(-52, -26) + floor()


def scene_shop():
    awning = "".join(path(f"M{x} -24 H{x + 20} V-10 Q{x + 10} 0 {x} -10 Z", C["accent" if i % 2 == 0 else "snow"], w=2.4)
                     for i, x in enumerate(range(-40, 40, 20)))
    return (backdrop() + path("M-34 -8 H34 V38 H-34 Z", C["sand"]) + path("M-24 8 H-4 V24 H-24 Z", C["lake"], w=2.4)
            + path("M6 38 V8 H24 V38", C["wood"], w=2.6) + path("M-32 -40 H32 L40 -24 H-40 Z", C["accent"]) + awning
            + tree(56, 24, .5) + floor())


def scene_search():
    return (backdrop("lake") + at(-10, 6, path("M-30 20 L-4 -22 L22 20 Z", C["rock"]) + blob("M-12 -9 L-4 -22 L5 -9 L-1 -11 L-4 -6 L-8 -11 Z", C["snow"]))
            + circle(-6, -6, 32, "none", w=5) + path("M18 20 L44 42", w=9) + path("M18 20 L44 42", stroke=C["wood"], w=3.4) + floor(48))


def scene_help():
    post = path("M-3 40 V-30 H5 V40", C["wood"])
    boards = (path("M-34 -28 H20 L32 -18 L20 -8 H-34 Z", C["sand"]) + path("M34 0 H-18 L-30 10 L-18 20 H34 Z", C["sage"])
              + path("M-24 -18 H8 M-10 10 H22", w=2.6))
    return backdrop() + post + boards + grass(-34, 40) + grass(30, 40) + floor()


def grass(x, y):
    return path(f"M{x - 8} {y} L{x - 10} {y - 9} M{x} {y} V{y - 13} M{x + 8} {y} L{x + 11} {y - 8}", w=2.4)


def scene_star():
    star = "M0 -40 L11 -14 L39 -12 L17 7 L24 35 L0 20 L-24 35 L-17 7 L-39 -12 L-11 -14 Z"
    return backdrop("sand") + path(star, C["sun"], w=3.2) + spark(-52, -20) + spark(50, -30, .9) + floor(46)


SCENES = {"trip": scene_trip, "gear": scene_gear, "meal": scene_meal, "chat": scene_chat, "map": scene_map,
          "friends": scene_friends, "shop": scene_shop, "search": scene_search, "help": scene_help, "star": scene_star}


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
    parts += [(f"_scene{k.title()}", fn) for k, fn in SCENES.items()]
    parts += [(f"_{fn.__name__.replace('_s', 'S').replace('_p', 'P').replace('_g', 'G')}", fn) for fn in MARK]
    out = ["// GENERATED by tool/art/generate.py - do not edit.", "// dart format off", "// ignore_for_file: type=lint", "",
           "import 'art_model.dart';", ""]
    out += [dart(name, draw(fn)) for name, fn in parts]
    out.append("const artScenes = {" + ", ".join(f"ArtScene.{k}: _scene{k.title()}" for k in SCENES) + "};")
    out.append("const artMark = [_markSky, _markSun, _markPeak, _markGround, _markStone1, _markStone2, _markStone3, _markStone4];")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"{os.path.normpath(OUT)}: {os.path.getsize(OUT) // 1024} KB")


if __name__ == "__main__":
    main()
