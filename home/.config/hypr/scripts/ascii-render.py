#!/usr/bin/env python3
# ascii-render.py <in> <out> [WxH] – the login screen's ASCII look as a still picture (for the lock screen, which can't
# run the login's live shader): one bold mono character per 9×16 cell, " .`:-=+*cox%#@" from dark to bright, with a
# soft glow underneath. Made by Claude.
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageChops
src, out = sys.argv[1], sys.argv[2]
W, H = map(int, (sys.argv[3] if len(sys.argv) > 3 else "2560x1440").split("x"))
CW, CH, CHARS = 9, 16, " .`:-=+*cox%#@"
cols, rows = -(-W // CW), -(-H // CH)
img = Image.open(src).convert("L")
s = max(cols / img.width, rows / img.height)            # cover, like the login
img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
l, t = (img.width - cols) // 2, (img.height - rows) // 2
img = ImageEnhance.Contrast(img.crop((l, t, l + cols, t + rows))).enhance(1.1)
font = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf", 13)
glyph = Image.new("L", (W, H), 0); d = ImageDraw.Draw(glyph)
px = img.load()
for y in range(rows):
    for x in range(cols):
        v = px[x, y] / 255
        ch = CHARS[min(len(CHARS) - 1, int(v * len(CHARS)))]
        if ch != " " and v > 0.07:
            d.text((x * CW + CW / 2, y * CH + CH / 2), ch, fill=int(255 * min(1, 0.95 * v ** 1.35)), font=font, anchor="mm")
glow = ImageEnhance.Brightness(glyph.filter(ImageFilter.GaussianBlur(10))).enhance(0.85)
ImageChops.lighter(glyph, glow).convert("RGB").save(out)
