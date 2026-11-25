"""Hand-drawn rendering: wobbly variable-width ink and loose watercolour fills, baked into plain paths."""
import math
import random
import re

rng = random.Random(11)
_clip = 0
CALM = 1.0  # 1 = loose sketch, lower = steadier lines


def parse(d):
    """Returns [(points, closed)] for the M L H V h C Q Z subset used by the sheet."""
    tok = re.findall(r"[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?", d)
    subs, pts, i, cmd, cur = [], [], 0, None, (0.0, 0.0)

    def num():
        nonlocal i
        i += 1
        return float(tok[i - 1])

    def line(p):
        nonlocal cur
        n = max(1, int(math.dist(cur, p) / 2.5))
        pts.extend((cur[0] + (p[0] - cur[0]) * k / n, cur[1] + (p[1] - cur[1]) * k / n) for k in range(1, n + 1))
        cur = p

    def curve(*c):
        nonlocal cur
        ctrl = [cur, *c]
        length = sum(math.dist(a, b) for a, b in zip(ctrl, ctrl[1:]))
        n = max(4, int(length / 2.5))
        for k in range(1, n + 1):
            t, q = k / n, ctrl
            while len(q) > 1:
                q = [(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t) for a, b in zip(q, q[1:])]
            pts.append(q[0])
        cur = ctrl[-1]

    while i < len(tok):
        if tok[i].isalpha():
            cmd = tok[i]
            i += 1
        if cmd == "M":
            if pts:
                subs.append((pts, False))
            cur = (num(), num())
            pts = [cur]
            cmd = "L"
        elif cmd == "L":
            line((num(), num()))
        elif cmd == "H":
            line((num(), cur[1]))
        elif cmd == "h":
            line((cur[0] + num(), cur[1]))
        elif cmd == "V":
            line((cur[0], num()))
        elif cmd == "v":
            line((cur[0], cur[1] + num()))
        elif cmd == "Q":
            curve((num(), num()), (num(), num()))
        elif cmd == "C":
            curve((num(), num()), (num(), num()), (num(), num()))
        elif cmd == "Z":
            if pts:
                line(pts[0])
                subs.append((pts, True))
                cur = pts[0]
                pts = []
            cmd = None
        else:
            raise ValueError(f"unsupported {cmd} in {d}")
    if len(pts) > 1:
        subs.append((pts, False))
    return subs


def wobble(pts, amp):
    ph = [rng.uniform(0, 6.28) for _ in range(4)]
    amp *= CALM
    out = []
    for x, y in pts:
        dx = math.sin(x * .061 + y * .043 + ph[0]) + .45 * math.sin(x * .19 - y * .17 + ph[1])
        dy = math.sin(x * .047 - y * .066 + ph[2]) + .45 * math.sin(x * .16 + y * .21 + ph[3])
        out.append((x + dx * amp, y + dy * amp))
    return out


def size_of(pts):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return max(max(xs) - min(xs), max(ys) - min(ys))


def poly(pts, close=True):
    return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + (" Z" if close else "")


def ink(d, color, width, extra=""):
    """Outline as a filled ribbon whose width swells and tapers like a pen stroke."""
    out = []
    for pts, closed in parse(d):
        pts = wobble(pts, min(.95, .25 + size_of(pts) * .012))
        if "dasharray" in extra:
            out.append(f'<path d="{poly(pts, False)}" fill="none" stroke="{color}" stroke-width="{width}" '
                       f'stroke-linecap="round" {extra}/>')
            continue
        left, right, travelled = [], [], 0.0
        total = sum(math.dist(a, b) for a, b in zip(pts, pts[1:])) or 1
        ph, freq = rng.uniform(0, 6.28), rng.uniform(.035, .07)
        halves = []
        for k, p in enumerate(pts):
            a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
            tx, ty = b[0] - a[0], b[1] - a[1]
            norm = math.hypot(tx, ty) or 1
            if k:
                travelled += math.dist(pts[k - 1], p)
            half = width / 2 * (1.02 + CALM * (.27 * math.sin(travelled * freq + ph) + .08 * math.sin(travelled * .31 + ph * 2)))
            if not closed:
                edge = min(travelled, total - travelled)
                half *= .62 + .38 * min(1, edge / 11)
            halves.append(half)
            nx, ny = -ty / norm * half, tx / norm * half
            left.append((p[0] + nx, p[1] + ny))
            right.append((p[0] - nx, p[1] - ny))
        shape = f"{poly(left)} {poly(right[::-1])}" if closed else poly(left + right[::-1])
        out.append(f'<path d="{shape}" fill="{color}"/>')
        for (x, y), r in ((pts[0], halves[0]), (pts[-1], halves[-1])):
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{color}"/>')
        # corners of a ribbon pinch; dots keep them round
        for k in range(1, len(pts) - 1):
            (ax, ay), (bx, by), (cx, cy) = pts[k - 1], pts[k], pts[k + 1]
            turn = abs(math.atan2(cy - by, cx - bx) - math.atan2(by - ay, bx - ax))
            if .6 < min(turn, 6.283 - turn):
                out.append(f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="{halves[k]:.2f}" fill="{color}"/>')
        if total > 120 and CALM > .6:  # faint second pass, as if the line was gone over twice
            ghost = wobble(pts, 1.5)
            a = rng.randint(0, len(ghost) // 3)
            b = rng.randint(len(ghost) * 2 // 3, len(ghost))
            out.append(f'<path d="{poly(ghost[a:b], False)}" fill="none" stroke="{color}" stroke-width="0.9" '
                       f'stroke-linecap="round" opacity="0.38"/>')
    return "".join(out)


def wash(d, color, opacity=1, under=None):
    """Colour laid slightly off the line, with pooled edges and uneven pigment."""
    global _clip
    out = []
    for pts, _ in parse(d):
        size = size_of(pts)
        amp = min(2.4, .4 + size * .022)
        if under and opacity == 1:
            out.append(f'<path d="{poly(pts)}" fill="{under}"/>')
        off = min(2.8, size * .035) * CALM
        loose = [(x + off, y + off * .55) for x, y in wobble(pts, amp)]
        _clip += 1
        shape = poly(loose)
        out.append(f'<g opacity="{opacity}"><clipPath id="w{_clip}"><path d="{shape}"/></clipPath>'
                   f'<path d="{shape}" fill="{color}" opacity="0.9"/><g clip-path="url(#w{_clip})">')
        xs, ys = [p[0] for p in loose], [p[1] for p in loose]
        for _ in range(int(min(9, 2 + size / 30))):
            x, y = rng.uniform(min(xs), max(xs)), rng.uniform(min(ys), max(ys))
            tone, o = rng.choice([("light", .42), ("light", .28), ("dark", .16)])
            out.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{size * rng.uniform(.08, .26):.1f}" '
                       f'ry="{size * rng.uniform(.04, .14):.1f}" transform="rotate({rng.randint(-35, 35)} {x:.1f} {y:.1f})" '
                       f'fill="url(#bloom-{tone})" opacity="{o * (.35 + .65 * CALM):.2f}"/>')
        out.append(f'<path d="{shape}" fill="none" stroke="#4a3526" stroke-width="{min(5, 1 + size * .03):.1f}" opacity="0.1"/>'
                   '</g></g>')
    return "".join(out)


def circle_path(x, y, r):
    pts = []
    start = rng.uniform(0, 6.28)
    ph = rng.uniform(0, 6.28)
    n = max(14, int(r * 2.4))
    for k in range(n):
        a = start + 6.2832 * k / n
        rr = r * (1 + .035 * CALM * math.sin(2 * a + ph))
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return poly(pts)
