"""Draws the app's illustrations and bakes them into Dart data.

Run from `app/`:  python3 -I tool/art/generate.py

Scenes are written as small SVG-like paths, roughened by `handdrawn.py`, then flattened into polygons so the app can
paint them itself (no SVG package) and colour them per theme. Colours are named roles here; their values live in
`lib/shared/brand/art/art_palette.dart`.
"""
import math
import os
import random
import re
import struct
import sys
import zlib
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

GRAIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "art", "grain.png")

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


# ------------------------------------------------------------------ covers (390 x 380, the page starts under y=380)

def sky():
    return (f'<rect x="0" y="0" width="390" height="380" fill="{C["skyTop"]}"/>'
            + hd.wash("M-20 130 C80 96 170 150 260 120 C320 100 380 130 410 118 V390 H-20 Z", C["skyMid"], .85)
            + hd.wash("M-20 190 C90 168 200 214 410 176 V390 H-20 Z", C["skyLow"], .7))


def day_sky():
    return sun(86, 114, 24) + cloud(262, 80, .75) + cloud(44, 172, .5) + bird(176, 90, .8) + bird(200, 106, .55)


def night_sky():
    moon = path("M96 118 C128 126 132 166 100 180 C84 186 70 180 62 171 C90 168 112 146 96 118 Z", C["glow"])
    star = "M0 -11 Q2 -2 11 0 Q2 2 0 11 Q-2 2 -11 0 Q-2 -2 0 -11 Z"
    stars = "".join(at(x, y, blob(star, C["glow"]), s) for x, y, s in
                    [(40, 112, .6), (150, 106, .8), (188, 138, .45), (300, 100, .6), (348, 146, .9), (128, 150, .4)])
    dots = "".join(circle(x, y, 1.8, C["snow"], None) for x, y in
                   [(30, 156), (120, 96), (210, 92), (318, 132), (368, 100), (172, 168)])
    return at(0, -32, moon + stars + dots)  # clear of the raised landforms


def paper_edge():
    return blob("M-4 364 C60 350 120 368 200 356 C270 346 330 362 394 352 V390 H-4 Z", C["paper"])


def cover_peak():
    peak = "M70 330 L226 158 Q240 142 256 158 L400 306 V390 H70 Z"
    o = [hill("M-8 244 L52 188 L92 216 L142 176 L190 220 V390 H-8 Z", "rangeFar"),
         blob(peak, C["peak"]), blob("M240 150 Q250 150 256 158 L400 306 V390 H318 L262 232 Z", C["peakShade"]),
         blob("M196 191 L226 158 Q240 142 256 158 L292 195 L270 186 L254 208 L238 182 L220 204 L210 188 Z", C["snow"]),
         path("M196 191 L210 188 L220 204 L238 182 L254 208 L270 186 L292 195", w=2.2),
         path("M70 330 L226 158 Q240 142 256 158 L400 306", w=2.6),
         hill("M-8 282 C50 240 108 262 160 292 C220 326 300 270 398 284 V390 H-8 Z", "hillBack"),
         hill("M-8 336 C70 300 150 340 232 322 C300 306 350 322 398 312 V390 H-8 Z", "hillFront")]
    o += [pine(x, y, s) for x, y, s in [(24, 312, .9), (52, 322, .6), (330, 306, .75), (362, 298, 1.05)]]
    return "".join(o)


def raised(dy, body):
    """Moves a scene's subject up so the info card does not hide it; the ground below stays filled."""
    return at(0, -dy, body)


def cover_lake():
    o = [hill("M-8 214 L70 124 L116 170 L180 106 L246 176 L300 136 L398 218 V390 H-8 Z", "rangeFar"),
         blob("M158 128 L180 106 L204 131 L192 128 L182 142 L170 126 Z", C["snow"]),
         path("M158 128 L170 126 L182 142 L192 128 L204 131", w=2.2),
         hill("M-8 218 C60 192 130 226 200 208 C270 192 330 218 398 202 V390 H-8 Z", "hillBack")]
    water = "M52 236 C110 216 270 214 340 234 C384 250 300 262 318 276 C322 300 190 296 128 292 C62 296 80 272 44 266 C6 258 8 246 52 236 Z"
    o.append(path(water, C["lake"]))
    o += [path(f"M{x} {y} h{n}", w=2.2) for x, y, n in [(92, 246, 28), (128, 246, 8), (196, 258, 40), (160, 274, 20), (250, 242, 20)]]
    o += [pine(x, y, s) for x, y, s in [(26, 230, 1.0), (56, 226, .66), (340, 220, .74), (368, 228, 1.05)]]
    o.append(hill("M-8 332 C80 306 170 346 250 322 C310 306 360 322 398 314 V390 H-8 Z", "hillFront"))
    return "".join(o)


def cover_hut():
    back = [hill("M-8 262 C30 180 100 160 160 200 C200 130 300 128 340 200 C362 184 384 200 398 224 V390 H-8 Z", "rangeFar"),
            hill("M-8 300 C70 264 150 300 220 286 C290 270 340 290 398 278 V390 H-8 Z", "hillBack")]
    house = [blob("M150 232 H262 V292 H150 Z", C["wood"]), blob("M234 232 H262 V292 H234 Z", C["tentShade"]),
             path("M150 232 V292 H262 V232"), path("M234 190 V166 H250 V204", C["metal"]),
             path("M132 238 L198 180 Q206 174 214 180 L282 238 Z", C["accent"]),
             path("M164 224 L186 205", C["snow"], C["snow"], 2.4),
             path("M195 292 V260 Q209 246 223 260 V292", C["wood"]),
             path("M161 252 H183 V272 H161 Z", C["glow"]), path("M172 252 V272 M161 262 H183", w=2.2),
             path("M234 252 H253 V272 H234 Z", C["glow"]), path("M244 252 V272 M234 262 H253", w=2.2),
             path("M242 158 C236 150 252 148 246 140", w=2.6),
             pine(62, 276, 1.15), pine(104, 284, .75), tree(322, 276, .95, "tent"), tree(358, 282, .66, "accent"),
             path("M206 296 C196 312 232 320 214 336 C202 346 216 352 208 360", w=2.8, dash="9 9")]
    front = hill("M-8 346 C80 322 180 362 260 340 C320 326 364 340 398 332 V390 H-8 Z", "hillFront")
    return raised(36, "".join(back + house)) + front


def cover_forest():
    o = [hill("M-8 196 C50 150 90 192 140 170 C190 148 220 110 262 128 C310 148 330 184 398 156 V390 H-8 Z", "rangeFar"),
         hill("M-8 232 C60 210 110 174 170 206 C230 240 300 192 398 210 V390 H-8 Z", "hillBack")]
    o += [pine(x, y, s) for x, y, s in [(34, 234, .7), (66, 244, .95), (98, 238, .6), (290, 230, .65), (322, 240, .95), (356, 232, .75)]]
    o.append(hill("M-8 282 C80 248 170 290 250 266 C310 250 360 266 398 258 V390 H-8 Z", "hillFront"))
    o.append(path("M150 330 C190 306 160 284 206 272 C236 262 224 244 252 232", stroke=C["snow"], w=3.2, dash="8 9"))
    o += [pine(x, y, s) for x, y, s in [(20, 296, 1.05), (58, 312, .8), (336, 292, .85), (372, 286, 1.15)]]
    return "".join(o)


COVERS = {"peak": cover_peak, "lake": cover_lake, "hut": cover_hut, "forest": cover_forest}


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


# ------------------------------------------------------------------ card vignettes: a small scene with air around it
# 390 x 150, the ground line at y = 126; shown whole on a pale tint

def vignette(subject):
    return (subject + path("M92 126 H252 M263 126 H300", w=2.8) + path("M112 137 h22 M236 140 h30 M152 142 h8", C["wood"], C["wood"], 1.8))


def vignette_day():
    return sun(300, 40, 13) + cloud(84, 36, .55) + cloud(248, 20, .34) + bird(252, 56, .45)


def vignette_night():
    moon = path("M296 24 C316 28 320 52 300 61 C291 65 282 63 277 58 C294 56 308 43 296 24 Z", C["glow"])
    star = "M0 -11 Q2 -2 11 0 Q2 2 0 11 Q-2 2 -11 0 Q-2 -2 0 -11 Z"
    return moon + "".join(at(x, y, blob(star, C["glow"]), s) for x, y, s in
                          [(84, 34, .45), (120, 58, .3), (248, 22, .4), (320, 74, .28)])


def small_pines(*spots):
    return "".join(pine(x, y, s) for x, y, s in spots)


def vignette_peak():
    far = "M110 126 L152 78 L176 104 L214 66 L286 126 Z"
    peak = "M140 126 L190 52 Q198 42 206 52 L256 126 Z"
    return vignette(blob(far, C["rangeFar"]) + path(far, w=2) + blob(peak, C["rock"]) + blob("M198 47 Q203 47 206 52 L256 126 H224 L200 84 Z", C["rockShade"])
                    + blob("M176 73 L190 52 Q198 42 206 52 L220 73 L210 68 L203 79 L194 66 L185 77 L181 70 Z", C["snow"])
                    + path("M176 73 L181 70 L185 77 L194 66 L203 79 L210 68 L220 73", w=1.8) + path(peak, w=2.6)
                    + small_pines((112, 121, .55), (132, 123, .38), (268, 120, .62)))


def vignette_lake():
    far = "M118 118 L160 66 L184 94 L214 54 L272 118 Z"
    water = "M140 128 C170 118 234 118 262 127 C280 134 244 138 250 143 C252 152 190 150 164 148 C138 150 148 140 132 137 C116 134 122 130 140 128 Z"
    return vignette(blob(far, C["rock"]) + blob("M199 75 L214 54 L230 74 L221 71 L214 80 L207 70 Z", C["snow"]) + path(far, w=2.4)
                    + path(water, C["lake"], w=2.4) + path("M168 134 h20 M214 140 h26", w=1.8)
                    + small_pines((108, 121, .7), (130, 123, .46), (264, 121, .54), (286, 119, .72)))


def vignette_hut():
    back = "M112 126 C130 82 164 76 190 98 C210 62 252 66 280 126 Z"
    return vignette(blob(back, C["rangeFar"]) + path(back, w=2)
                    + path("M168 96 H224 V126 H168 Z", C["wood"], w=2.6) + path("M156 100 L192 70 Q196 67 200 70 L236 100 Z", C["accent"], w=2.6)
                    + path("M190 126 V111 Q196 104 202 111 V126", C["tentShade"], w=2)
                    + path("M174 106 H185 V117 H174 Z M208 106 H219 V117 H208 Z", C["glow"], w=1.8)
                    + small_pines((124, 121, .62), (144, 123, .42)) + tree(258, 120, .5, "tent") + tree(280, 123, .34, "accent"))


def vignette_forest():
    far = "M108 126 C132 88 164 106 188 92 C214 74 244 88 286 126 Z"
    return vignette(blob(far, C["sage"]) + path(far, w=2.2)
                    + small_pines((128, 118, .72), (152, 121, 1.0), (176, 122, .62), (218, 120, .86), (242, 122, .56), (264, 118, .76))
                    + path("M184 150 C214 140 180 134 198 126", stroke=C["wood"], w=2.2, dash="5 6"))


VIGNETTES = [vignette_peak, vignette_lake, vignette_hut, vignette_forest, vignette_day, vignette_night]


# ------------------------------------------------------------------ the page behind every screen
# sky: 390 x 320, hung from the top; hills: 390 x 130, standing on the bottom edge

def page_sky():
    return (hd.wash("M-20 -20 H410 V150 C320 190 250 130 170 166 C100 194 40 150 -20 176 Z", C["skyTop"], .7)
            + hd.wash("M-20 130 C80 100 160 180 260 140 C320 118 370 156 410 130 V280 C320 310 230 250 140 292 C80 316 30 280 -20 298 Z",
                      C["skyMid"], .5))


def page_sky_day():
    return sun(330, 132, 18) + cloud(222, 120, .5) + cloud(356, 186, .38) + bird(268, 160, .55)


def page_sky_night():
    moon = path("M322 108 C346 114 350 142 324 154 C312 159 300 156 294 150 C316 146 334 130 322 108 Z", C["glow"])
    star = "M0 -11 Q2 -2 11 0 Q2 2 0 11 Q-2 2 -11 0 Q-2 -2 0 -11 Z"
    stars = "".join(at(x, y, blob(star, C["glow"]), s) for x, y, s in
                    [(230, 112, .5), (266, 160, .35), (362, 190, .6), (184, 134, .3)])
    return moon + stars


def page_hills():
    far = hill("M-8 62 C50 24 110 70 170 46 C240 20 300 64 398 30 V140 H-8 Z", "meadowFar")
    near = hill("M-8 100 C70 70 150 110 230 88 C300 70 350 94 398 80 V140 H-8 Z", "meadow")
    trees = "".join(pine(x, y, s) for x, y, s in [(24, 100, .72), (48, 106, .5), (318, 86, .55), (346, 90, .85), (372, 94, .62)])
    return far + near + trees


PAGE = [page_sky, page_sky_day, page_sky_night, page_hills]


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


def write_grain(size=192):
    """A tile of paper grain: transparent, with scattered faint specks. The app tints and repeats it."""
    rng = random.Random(7)
    rows = b""
    for _ in range(size):
        rows += b"\0" + b"".join(bytes((255, 255, 255, rng.choice((0, 0, 0, 0, 0, 40, 70, 120)) if rng.random() < .6 else 0))
                                 for _ in range(size))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(GRAIN), exist_ok=True)
    with open(GRAIN, "wb") as f:
        f.write(png)


def main():
    hd.CALM = .5
    parts = [("_sky", sky), ("_daySky", day_sky), ("_nightSky", night_sky), ("_paperEdge", paper_edge)]
    parts += [(f"_cover{k.title()}", fn) for k, fn in COVERS.items()]
    parts += [(f"_icon{k[0].upper()}{k[1:]}", fn) for k, fn in ICONS.items()]
    parts += [(f"_scene{k.title()}", fn) for k, fn in SCENES.items()]
    parts += [(f"_{fn.__name__.replace('_s', 'S').replace('_p', 'P').replace('_g', 'G')}", fn) for fn in MARK]
    parts += [("_" + "".join(w if i == 0 else w.title() for i, w in enumerate(fn.__name__.split("_"))), fn) for fn in PAGE]
    parts += [("_" + "".join(w if i == 0 else w.title() for i, w in enumerate(fn.__name__.split("_"))), fn) for fn in VIGNETTES]
    out = ["// GENERATED by tool/art/generate.py - do not edit.", "// dart format off", "// ignore_for_file: type=lint", "",
           "import 'art_model.dart';", ""]
    out += [dart(name, draw(fn)) for name, fn in parts]
    out.append("const artSky = _sky;\nconst artDaySky = _daySky;\nconst artNightSky = _nightSky;\nconst artPaperEdge = _paperEdge;")
    out.append("const artCovers = [" + ", ".join(f"_cover{k.title()}" for k in COVERS) + "];")
    out.append("const artIcons = {" + ", ".join(f"ArtIcon.{k}: _icon{k[0].upper()}{k[1:]}" for k in ICONS) + "};")
    out.append("const artScenes = {" + ", ".join(f"ArtScene.{k}: _scene{k.title()}" for k in SCENES) + "};")
    out.append("const artMark = [_markSky, _markSun, _markPeak, _markGround, _markStone1, _markStone2, _markStone3, _markStone4];")
    out.append("const artPageSky = _pageSky;\nconst artPageSkyDay = _pageSkyDay;\nconst artPageSkyNight = _pageSkyNight;\nconst artPageHills = _pageHills;")
    out.append("const artVignettes = [_vignettePeak, _vignetteLake, _vignetteHut, _vignetteForest];")
    out.append("const artVignetteDay = _vignetteDay;\nconst artVignetteNight = _vignetteNight;")
    write_grain()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"{os.path.normpath(OUT)}: {os.path.getsize(OUT) // 1024} KB")


if __name__ == "__main__":
    main()
