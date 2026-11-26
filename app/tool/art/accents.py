"""Renders the corner accents of the top-level pages: two watercolour washes and two small plant sprigs.

Run from `app/`:  python3 -I -B tool/art/accents.py
Needs Google Chrome, so macOS. Coordinates are those of a 390 wide page whose bottom is at y = 756.
"""
import math
import os
import subprocess
import tempfile

APP = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(APP, "assets", "accents")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SCALE = 3


def blot(cx, cy, rx, ry, color, o, seed, i):
    """A soft bloom with a torn edge and pooled rim."""
    f = (f'<filter id="w{i}" x="-40%" y="-40%" width="180%" height="180%">'
         f'<feTurbulence type="fractalNoise" baseFrequency=".018" numOctaves="4" seed="{seed}"/>'
         f'<feDisplacementMap in="SourceGraphic" scale="60" xChannelSelector="R" yChannelSelector="G"/>'
         f'<feGaussianBlur stdDeviation="1.2"/></filter>')
    return (f'{f}<g filter="url(#w{i})"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{color}" opacity="{o}"/>'
            f'<ellipse cx="{cx + 14}" cy="{cy - 8}" rx="{rx * .62}" ry="{ry * .6}" fill="{color}" opacity="{o * .75}"/>'
            f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" stroke="{color}" stroke-width="3" opacity="{o * .6}"/></g>')


def sprig(x, y, s, angle, color, bloom):
    leaves = ""
    for t, side in [(.18, 1), (.3, -1), (.44, 1), (.56, -1), (.7, 1), (.8, -1)]:
        py, px = -90 * t, 10 * math.sin(t * 2.4)
        leaf = f"M{px:.1f} {py:.1f} q{16 * side} -2 {22 * side} -16 q{-15 * side} 0 {-22 * side} 16Z"
        leaves += f'<path d="{leaf}" fill="{color}" opacity=".28"/><path d="{leaf} M{px:.1f} {py:.1f} l{14 * side} -11" fill="none"/>'
    flowers = "".join(f'<circle cx="{fx}" cy="{fy}" r="{r}" fill="{bloom}" opacity=".7" stroke="none"/>'
                      f'<circle cx="{fx}" cy="{fy}" r="{r}" fill="none"/>' for fx, fy, r in [(8, -96, 4.5), (-4, -104, 3.2), (17, -88, 3)])
    return (f'<g transform="translate({x},{y}) rotate({angle}) scale({s})" stroke="#6b7a5e" stroke-width="1.1" '
            f'stroke-linecap="round" fill="none"><path d="M0 6 C2 -30 14 -60 7 -94 M5 -70 Q-4 -86 -4 -102 M8 -66 Q16 -74 17 -86"/>'
            f"{leaves}{flowers}</g>")


# name: (view box on the page, drawing)
PIECES = {
    "wash_top": ((150, 0, 240, 250), blot(335, 62, 128, 92, "#9fbfae", .34, 3, 1) + blot(392, 150, 70, 56, "#a9c4d6", .3, 8, 2)),
    "wash_bottom": ((0, 476, 200, 280), blot(-6, 650, 100, 120, "#efc9a4", .3, 11, 3) + blot(70, 745, 90, 46, "#9fbfae", .22, 5, 4)),
    "sprig_left": ((0, 616, 100, 140), sprig(8, 748, .95, 24, "#7f9d77", "#d98b6a")),
    "sprig_right": ((300, 456, 90, 110), sprig(386, 556, .72, -32, "#7f9d77", "#e9b872")),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, ((x, y, w, h), body) in PIECES.items():
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SCALE}" height="{h * SCALE}" '
               f'viewBox="{x} {y} {w} {h}">{body}</svg>')
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "art.svg")
            with open(source, "w", encoding="utf-8") as f:
                f.write(svg)
            target = os.path.join(OUT, f"{name}.png")
            subprocess.run([CHROME, "--headless=new", "--disable-gpu", f"--user-data-dir={tmp}/profile", "--hide-scrollbars",
                            "--force-device-scale-factor=1", "--default-background-color=00000000",
                            f"--window-size={w * SCALE},{h * SCALE}", f"--screenshot={target}", f"file://{source}"],
                           check=True, capture_output=True, timeout=60)
    print("accents written")


if __name__ == "__main__":
    main()
