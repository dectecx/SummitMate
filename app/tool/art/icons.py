"""Renders the launcher icons from the app's mark (the `mark_*` layers of generate.py).

Run from `app/`:  python3 -I -B tool/art/icons.py
Needs Google Chrome (renders) and `sips` (resizes), so macOS.
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import generate as g  # noqa: E402
import handdrawn as hd  # noqa: E402

APP = os.path.abspath(os.path.join(HERE, "..", ".."))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# the light values of ArtPalette.mark
HEX = {"ink": "#3d342d", "paper": "#f1ede2", "snow": "#fbf9f3", "rock": "#a9856c", "sun": "#f2c94c", "sunShade": "#e0ab35",
       "accent": "#d9705a", "sand": "#e3d2ac", "skyTop": "#9fc3cc", "skyMid": "#efcfa8", "peak": "#8d7567",
       "peakShade": "#735e55", "ground": "#2b6863"}
BACKGROUND = [g.mark_sky, g.mark_sun, g.mark_peak, g.mark_ground]
FOREGROUND = [g.mark_stone1, g.mark_stone2, g.mark_stone3, g.mark_stone4]
IOS = {"20x20@1x": 20, "20x20@2x": 40, "20x20@3x": 60, "29x29@1x": 29, "29x29@2x": 58, "29x29@3x": 87, "40x40@1x": 40,
       "40x40@2x": 80, "40x40@3x": 120, "60x60@2x": 120, "60x60@3x": 180, "76x76@1x": 76, "76x76@2x": 152,
       "83.5x83.5@2x": 167, "1024x1024@1x": 1024}
ANDROID = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def layers(functions):
    hd.CALM = .5
    out = ""
    for fn in functions:
        hd.rng.seed(fn.__name__)  # the same lines as the app draws
        out += fn()
    for role in g.ROLES:
        if role in HEX:
            out = out.replace(g.C[role], HEX[role])
        else:
            assert g.C[role] not in out, f"no colour for {role}"
    return out


def render(body, view_box, size, path, transparent=False):
    blooms = "".join(f'<radialGradient id="bloom-{k}"><stop offset="0.35" stop-color="{c}"/>'
                     f'<stop offset="1" stop-color="{c}" stop-opacity="0"/></radialGradient>'
                     for k, c in [("light", "#fffaf0"), ("dark", "#3d2f24")])
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="{view_box}">'
           f"<defs>{blooms}</defs>{body}</svg>")
    with tempfile.TemporaryDirectory() as tmp:
        source = os.path.join(tmp, "art.svg")
        with open(source, "w", encoding="utf-8") as f:
            f.write(svg)
        args = [CHROME, "--headless=new", "--disable-gpu", f"--user-data-dir={tmp}/profile", "--hide-scrollbars",
                "--force-device-scale-factor=1", f"--window-size={size},{size}", f"--screenshot={path}"]
        if transparent:
            args.append("--default-background-color=00000000")
        subprocess.run(args + [f"file://{source}"], check=True, capture_output=True, timeout=60)


def resize(source, size, path):
    subprocess.run(["sips", "-z", str(size), str(size), source, "--out", path], check=True, capture_output=True)


def opaque(path):
    """App Store icons may not carry an alpha channel; a pass through maximum-quality JPEG drops it."""
    info = subprocess.run(["sips", "-g", "hasAlpha", path], check=True, capture_output=True, text=True).stdout
    if "hasAlpha: yes" in info:
        with tempfile.TemporaryDirectory() as tmp:
            jpg = os.path.join(tmp, "flat.jpg")
            subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100", path, "--out", jpg], check=True, capture_output=True)
            subprocess.run(["sips", "-s", "format", "png", jpg, "--out", path], check=True, capture_output=True)


def main():
    master = os.path.join(APP, "assets", "icon.png")
    render(layers(BACKGROUND + FOREGROUND), "0 0 400 400", 1024, master)
    opaque(master)
    iconset = os.path.join(APP, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for name, size in IOS.items():
        target = os.path.join(iconset, f"Icon-App-{name}.png")
        resize(master, size, target)
        opaque(target)
    res = os.path.join(APP, "android", "app", "src", "main", "res")
    with tempfile.TemporaryDirectory() as tmp:
        back, front = os.path.join(tmp, "back.png"), os.path.join(tmp, "front.png")
        # adaptive layers are 108dp of which 72dp show: the 400 artwork sits in the middle of 600
        render(layers(BACKGROUND), "-100 -100 600 600", 432, back)
        # the cairn is pulled a little inwards so every launcher mask leaves it whole
        render(f'<g transform="translate(24,24) scale(0.88)">{layers(FOREGROUND)}</g>', "-100 -100 600 600", 432, front, True)
        for density, factor in ANDROID.items():
            folder = os.path.join(res, f"mipmap-{density}")
            resize(master, int(48 * factor), os.path.join(folder, "ic_launcher.png"))
            resize(back, int(108 * factor), os.path.join(folder, "ic_launcher_background.png"))
            resize(front, int(108 * factor), os.path.join(folder, "ic_launcher_foreground.png"))
    print("icons written")


if __name__ == "__main__":
    main()
