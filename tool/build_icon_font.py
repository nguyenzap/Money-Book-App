"""Dựng font icon riêng MoneyBookIcons (hiện có 1 glyph: túi snack, U+E001).

    pip install fonttools skia-pathops pillow
    python tool/build_icon_font.py assets/fonts/MoneyBookIcons.ttf preview.png

Vẽ trên lưới 24px như Material Icons, nét 1.6px.
"""
import math, sys
import pathops
from pathops import Path, LineCap, LineJoin, op, PathOp
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.reverseContourPen import ReverseContourPen
from PIL import Image, ImageDraw, ImageFont

SW = 1.6  # stroke width on the 24 grid


def poly(pts, closed):
    p = Path()
    p.moveTo(*pts[0])
    for q in pts[1:]:
        p.lineTo(*q)
    if closed:
        p.close()
    return p


def stroke(pts, closed=False, w=SW):
    p = poly(pts, closed)
    p.stroke(w, LineCap.ROUND_CAP, LineJoin.ROUND_JOIN, 4)
    p.convertConicsToQuads()
    return p


def circle(cx, cy, r, n=48):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def xf(pts, ang, tx, ty):
    c, s = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    return [(x * c - y * s + tx, x * s + y * c + ty) for x, y in pts]


def union(paths):
    out = Path()
    for p in paths:
        out = op(out, p, PathOp.UNION)
    return out


# ---- bag, drawn upright around (0,0), then tilted 45deg -------------------
HW, HH, TOOTH = 3.7, 5.2, 0.8
BAG_ANG, BAG_C = 45, (9.0, 14.8)


def zig(y, out_sign, teeth=3):
    n = teeth * 2
    return [(-HW + 2 * HW * i / n, y + (out_sign * TOOTH if i % 2 else 0)) for i in range(n + 1)]


top = zig(-HH, -1)
bottom = list(reversed(zig(HH, +1)))
outline = top + bottom  # right side and left side are the joins
bag_outline = xf(outline, BAG_ANG, *BAG_C)
seal_t = xf([(-HW, -HH + 2.0), (HW, -HH + 2.0)], BAG_ANG, *BAG_C)
seal_b = xf([(-HW, HH - 2.0), (HW, HH - 2.0)], BAG_ANG, *BAG_C)
dot = xf(circle(0, 0.2, 1.35), BAG_ANG, *BAG_C)

bag_fill = poly(bag_outline, True)  # used to hide the chip behind the bag


# ---- chips: half-ovals with a flat (broken) edge ---------------------------
def chip(cx, cy, ang, a, b, dots):
    arc = [(a * math.cos(math.pi * i / 24), -b * math.sin(math.pi * i / 24)) for i in range(25)]
    pts = xf(arc, ang, cx, cy)
    d = [xf(circle(dx, dy, 0.5, 16), ang, cx, cy) for dx, dy in dots]
    return pts, d


chipA, dotsA = chip(18.0, 7.6, 45, 3.2, 3.0, [(-0.8, -1.2), (0.9, -1.4)])
chipB, dotsB = chip(12.9, 9.9, 20, 2.7, 2.3, [])

parts = [
    stroke(bag_outline, True),
    stroke(seal_t),
    stroke(seal_b),
    poly(dot, True),
    stroke(chipA, True),
    *[poly(d, True) for d in dotsA],
]
chipB_stroke = op(stroke(chipB, True), bag_fill, PathOp.DIFFERENCE)
parts.append(chipB_stroke)

glyph = union(parts)
glyph.simplify()
b = glyph.bounds
print("bounds", [round(v, 2) for v in b], file=sys.stderr)

# ---- font ------------------------------------------------------------------
UPM = 1536  # 64 units per grid px
S = UPM / 24
fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder([".notdef", "snack"])
fb.setupCharacterMap({0xE001: "snack"})
pen = TTGlyphPen(None)
glyph.draw(TransformPen(Cu2QuPen(ReverseContourPen(pen), 1.0), (S, 0, 0, -S, 0, UPM)))
empty = TTGlyphPen(None).glyph()
fb.setupGlyf({".notdef": empty, "snack": pen.glyph()})
fb.setupHorizontalMetrics({".notdef": (UPM, 0), "snack": (UPM, 0)})
fb.setupHorizontalHeader(ascent=UPM, descent=0)
fb.setupNameTable({"familyName": "MoneyBookIcons", "styleName": "Regular"})
fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=UPM, usWinDescent=0)
fb.setupPost()
fb.save(sys.argv[1])

# ---- preview ---------------------------------------------------------------
sizes = [24, 32, 48, 160]
img = Image.new("RGB", (sum(sizes) + 20 * (len(sizes) + 1), 200), "white")
x = 20
for sz in sizes:
    f = ImageFont.truetype(sys.argv[1], sz)
    ImageDraw.Draw(img).text((x, 20), "", font=f, fill="black")
    x += sz + 20
img.save(sys.argv[2])
