"""Renders the corner accents of the top-level pages: two blurred watercolour washes.

Run from `app/`:  python3 -I -B tool/art/accents.py
Needs Google Chrome, so macOS. Coordinates are those of a 390 wide page whose bottom is at y = 756.
"""
import os
import subprocess
import tempfile

APP = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(APP, "assets", "accents")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SCALE = 3


def blot(cx, cy, rx, ry, color, o, seed, i):
    """A soft bloom, blurred until it has no edge of its own, so it never competes with what lies on it."""
    f = (f'<filter id="w{i}" x="-80%" y="-80%" width="260%" height="260%">'
         f'<feTurbulence type="fractalNoise" baseFrequency=".018" numOctaves="3" seed="{seed}"/>'
         f'<feDisplacementMap in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G"/>'
         f'<feGaussianBlur stdDeviation="22"/></filter>')
    return (f'{f}<g filter="url(#w{i})"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{color}" opacity="{o}"/>'
            f'<ellipse cx="{cx + 14}" cy="{cy - 8}" rx="{rx * .62}" ry="{ry * .6}" fill="{color}" opacity="{o * .5}"/></g>')


# name: (view box on the page, drawing)
PIECES = {
    "wash_top": ((150, 0, 240, 250), blot(335, 62, 128, 92, "#9fbfae", .34, 3, 1) + blot(392, 150, 70, 56, "#a9c4d6", .3, 8, 2)),
    "wash_bottom": ((0, 476, 200, 280), blot(-6, 650, 100, 120, "#efc9a4", .3, 11, 3) + blot(70, 745, 90, 46, "#9fbfae", .22, 5, 4)),
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
