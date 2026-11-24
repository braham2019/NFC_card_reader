#!/usr/bin/env python3
"""
A4 sheet(s) of portrait NFC album cards (54 x 85 mm): square art on top, white panel with
album + artist below. 10 cards per A4 page (cards rotated 90 deg), 1.5 mm bleed, crop ticks.

  pip install pillow reportlab
  python3 make_sheet.py                 # reads cards.json, writes nfc-cards-sheet.pdf
Print at 100% / "Actual size" (turn OFF "fit to page" / "fit to printable area").
"""
import json, os, sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader, simpleSplit
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CW, CH = 54.0, 85.0           # card, portrait (mm)
ART = 54.0                    # square art on top, text panel below
BLEED = 1.5
GAP = 2.0                     # between cards (bleeds overlap 1 mm inside the gap)
TICK_OFF, TICK_LEN = 0.5, 2.0 # crop ticks start 0.5 mm outside the bleed, 2 mm long
COLS, ROWS = 2, 5             # slots are 85 wide x 54 high (cards rotated)
MIN_PX = 600

def register_fonts():
    pairs = [
        ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
        ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
        ("/Library/Fonts/Arial.ttf", "/Library/Fonts/Arial Bold.ttf"),
        ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/arialbd.ttf"),
    ]
    for r, b in pairs:
        if os.path.exists(r) and os.path.exists(b):
            pdfmetrics.registerFont(TTFont("CardR", r)); pdfmetrics.registerFont(TTFont("CardB", b))
            return "CardR", "CardB"
    print("note: no TrueType font found, using Helvetica (fine for Western European text)")
    return "Helvetica", "Helvetica-Bold"
FR, FB = register_fonts()

def placeholder(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im = Image.new("RGB", (1000, 1000), (205, 205, 210))
    d = ImageDraw.Draw(im)
    d.line((0, 0, 1000, 1000), fill=(150, 150, 160), width=6)
    d.line((0, 1000, 1000, 0), fill=(150, 150, 160), width=6)
    im.save(path)

def fit(text, width_mm, font, sizes, max_lines):
    for s in sizes:
        lines = simpleSplit(text, font, s, width_mm * mm)
        if len(lines) <= max_lines:
            return s, lines
    s = sizes[-1]
    return s, simpleSplit(text, font, s, width_mm * mm)[:max_lines]

def draw_card(c, card, warn):
    """Portrait coordinates: origin bottom-left of the card, u across, v up."""
    path = os.path.join(HERE, card["art"])
    if not os.path.exists(path):
        placeholder(path); warn.append("%s: art missing, placeholder used" % card["album"])
    im = Image.open(path); size = min(im.size)
    if size < MIN_PX: warn.append("%s: art only %dpx" % (card["album"], size))
    im = im.convert("RGB")
    w, h = im.size; s = min(w, h)
    im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
    panel_h = CH - ART
    c.saveState()
    p = c.beginPath(); p.rect(-BLEED*mm, -BLEED*mm, (CW+2*BLEED)*mm, (CH+2*BLEED)*mm); c.clipPath(p, stroke=0, fill=0)
    c.setFillColorRGB(1, 1, 1); c.rect(-BLEED*mm, -BLEED*mm, (CW+2*BLEED)*mm, (panel_h+BLEED)*mm, stroke=0, fill=1)
    aw = CW + 2*BLEED
    q = c.beginPath(); q.rect(-BLEED*mm, panel_h*mm, aw*mm, (ART+BLEED)*mm); c.clipPath(q, stroke=0, fill=0)
    c.drawImage(ImageReader(im), -BLEED*mm, (panel_h-(aw-ART-BLEED))*mm, aw*mm, aw*mm)
    c.restoreState()
    c.saveState()
    tw = CW - 7
    asz, alines = fit(card["album"], tw, FB, [13, 12, 11, 10, 9], 3)
    rsz, rlines = fit(card["artist"], tw, FR, [9, 8, 7.5, 7], 2)
    lead_a, lead_r = asz * 1.15, rsz * 1.2
    block = len(alines)*lead_a + 2.0*mm + len(rlines)*lead_r
    y = (panel_h*mm + block) / 2 - asz
    c.setFillColorRGB(0.07, 0.07, 0.07); c.setFont(FB, asz)
    for ln in alines:
        c.drawString(3.5*mm, y, ln); y -= lead_a
    y -= 2.0*mm - (lead_a - asz) + 1
    c.setFillColorRGB(0.35, 0.35, 0.38); c.setFont(FR, rsz)
    for ln in rlines:
        c.drawString(3.5*mm, y, ln); y -= lead_r
    c.restoreState()

def main(out):
    cards = json.load(open(os.path.join(HERE, "cards.json"), encoding="utf-8"))
    pw, ph = A4
    sw, sh = CH*mm, CW*mm
    gx = GAP*mm
    total_w = COLS*sw + (COLS-1)*gx; total_h = ROWS*sh + (ROWS-1)*gx
    x0 = (pw - total_w)/2; y0 = (ph - total_h)/2
    per = COLS*ROWS
    c = canvas.Canvas(out, pagesize=A4)
    c.setTitle("NFC album cards"); warn = []
    for page in range(max(1, -(-len(cards)//per))):
        # crop ticks, outside the bleed and kept >= 5 mm from the paper edge
        c.setStrokeColorRGB(0, 0, 0); c.setLineWidth(0.2)
        off = (BLEED + TICK_OFF) * mm
        for row in range(ROWS):
            top = ph - y0 - row*(sh+gx)
            for yy in (top, top - sh):
                c.line(x0 - off - 3*mm, yy, x0 - off, yy)
                c.line(x0 + total_w + off, yy, x0 + total_w + off + 3*mm, yy)
        for col in range(COLS):
            left = x0 + col*(sw+gx)
            for xx in (left, left + sw):
                c.line(xx, ph - y0 + off, xx, ph - y0 + off + TICK_LEN*mm)
                c.line(xx, y0 - off, xx, y0 - off - TICK_LEN*mm)
        # 50 mm scale bar: if it does not measure 50 mm on paper, printing was scaled
        bx, by = 9*mm, ph/2
        c.line(bx, by - 25*mm, bx, by + 25*mm)
        c.line(bx - 1.5*mm, by - 25*mm, bx + 1.5*mm, by - 25*mm)
        c.line(bx - 1.5*mm, by + 25*mm, bx + 1.5*mm, by + 25*mm)
        c.setFont(FR, 5); c.setFillColorRGB(0, 0, 0)
        c.saveState(); c.translate(bx + 3*mm, by); c.rotate(90); c.drawCentredString(0, 0, "50 mm - print at 100%"); c.restoreState()
        for n in range(per):
            idx = page*per + n
            if idx >= len(cards): break
            col, row = n % COLS, n // COLS
            X = x0 + col*(sw+gx); Y = ph - y0 - (row+1)*sh - row*gx
            c.saveState(); c.translate(X, Y + sh); c.rotate(-90)
            draw_card(c, cards[idx], warn); c.restoreState()
        # inner marks (drawn AFTER the cards, because the bleeds cover the whole gap): in the gaps BETWEEN the cards (rows and columns) so you can see where to cut inside the sheet.
        # They stay inside the 2 mm gap, i.e. in the waste strip, never on a card.
        c.setStrokeColorRGB(0, 0, 0); c.setLineWidth(0.25)
        for row in range(1, ROWS):
            gy_top = ph - y0 - row*sh - (row-1)*gx          # bottom edge of the row above
            gy_bot = gy_top - gx                             # top edge of the row below
            for col in range(COLS):
                left = x0 + col*(sw+gx)
                for xx in (left, left + sw):                 # vertical ticks across the row gap, at the card edges
                    c.line(xx, gy_top, xx, gy_bot)
            for col in range(COLS - 1):                      # horizontal ticks across the column gap
                gx_l = x0 + col*(sw+gx) + sw
                for yy in (gy_top, gy_bot):
                    c.line(gx_l, yy, gx_l + gx, yy)
        c.showPage()
    c.save()
    for w in warn: print("WARN", w)
    print("wrote", out, "(%d cards, %d page(s))" % (len(cards), max(1, -(-len(cards)//per))))

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "nfc-cards-sheet.pdf"))
