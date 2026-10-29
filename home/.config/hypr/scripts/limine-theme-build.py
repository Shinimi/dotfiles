#!/usr/bin/env python3
# limine-theme-build.py <outdir> – builds the monochrome Limine boot menu theme:
#   wall.png     the login's ASCII landscape, dimmed so the menu reads on top of it
#   font.bin     JetBrains Mono as Limine's 8×16 code page 437 bitmap font (box lines drawn by hand so frames join up)
#   preview.png  roughly what the menu will look like (Limine itself can only be seen at boot)
# ~/limine-theme.sh copies the first two to /boot and writes the options. Made by Claude.
import os, sys, subprocess, unicodedata
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageFilter
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
here = os.path.dirname(os.path.abspath(__file__))
W, H = 2560, 1440

# ---------- wallpaper: the ASCII landscape at a third of its brightness, darker towards the middle ----------
src = os.path.expanduser("~/.config/hypr/lock/ascii-lock.png")
if not os.path.exists(src):
    subprocess.run([here + "/ascii-render.py", os.path.expanduser("~/.config/hypr/lock/ascii-background.jpg"), src], check=True)
wall = ImageEnhance.Brightness(Image.open(src).convert("RGB")).enhance(0.42)
vign = Image.new("L", (W, H), 0); ImageDraw.Draw(vign).ellipse((W * 0.12, H * 0.10, W * 0.88, H * 0.90), fill=150)
vign = vign.filter(ImageFilter.GaussianBlur(220))
wall = Image.composite(Image.new("RGB", (W, H), (6, 6, 6)), wall, vign)
d = ImageDraw.Draw(wall)
small = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf", 15)
d.text((W / 2, H - 58), "C A C H Y O S   ·   H Y P R L A N D", fill=(110, 110, 110), font=small, anchor="mm")
wall.save(out + "/wall.png", optimize=True)

# ---------- font: 256 glyphs, 8×16, 1 bit, rows top to bottom ----------
mono = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf", 13)
def box(ch):   # light/double box drawing and block shades, drawn exactly on the cell grid
    try: name = unicodedata.name(ch)
    except ValueError: return None
    g = [[0] * 8 for _ in range(16)]
    def hline(y, x0, x1):
        for x in range(x0, x1): g[y][x] = 1
    def vline(x, y0, y1):
        for y in range(y0, y1): g[y][x] = 1
    if name.startswith("BOX DRAWINGS"):
        n = name[len("BOX DRAWINGS "):]
        dbl_h = "DOUBLE HORIZONTAL" in n or ("DOUBLE" in n and "VERTICAL" not in n and "SINGLE" not in n) or "SINGLE AND HORIZONTAL DOUBLE" in n or n.startswith("DOUBLE") or "AND LEFT DOUBLE" in n or "AND RIGHT DOUBLE" in n or "HORIZONTAL DOUBLE" in n
        dbl_v = "DOUBLE VERTICAL" in n or "VERTICAL DOUBLE" in n or n.startswith("DOUBLE") or "DOUBLE AND" in n.replace("DOUBLE AND HORIZONTAL SINGLE", "DOUBLE AND") or "UP DOUBLE" in n or "DOWN DOUBLE" in n
        if "SINGLE" in n:   # mixed lines: which one is double is said explicitly
            dbl_h = "HORIZONTAL DOUBLE" in n or "LEFT DOUBLE" in n or "RIGHT DOUBLE" in n
            dbl_v = "VERTICAL DOUBLE" in n or "UP DOUBLE" in n or "DOWN DOUBLE" in n
        up = "UP" in n or "VERTICAL" in n; down = "DOWN" in n or "VERTICAL" in n
        left = "LEFT" in n or "HORIZONTAL" in n; right = "RIGHT" in n or "HORIZONTAL" in n
        cx, cy = 3, 7
        hy = [cy - 1, cy + 1] if dbl_h else [cy]; vx = [cx - 1, cx + 1] if dbl_v else [cx]
        for y in hy:
            if left: hline(y, 0, cx + 2 if not dbl_v else (vx[0] + 1 if y == hy[0] and up and not down else vx[-1] + 1))
            if right: hline(y, cx if not dbl_v else vx[0], 8)
        for x in vx:
            if up: vline(x, 0, cy + 1 if not dbl_h else hy[-1] + 1)
            if down: vline(x, cy if not dbl_h else hy[0], 16)
        return g
    shades = {"LIGHT SHADE": 4, "MEDIUM SHADE": 2, "DARK SHADE": 1}
    if name in shades:
        k = shades[name]
        for y in range(16):
            for x in range(8): g[y][x] = 1 if (x + y * (1 if k != 1 else 3)) % k == 0 or (k == 1 and (x + y) % 4) else 0
        return g
    blocks = {"FULL BLOCK": (0, 0, 8, 16), "LOWER HALF BLOCK": (0, 8, 8, 16), "UPPER HALF BLOCK": (0, 0, 8, 8),
              "LEFT HALF BLOCK": (0, 0, 4, 16), "RIGHT HALF BLOCK": (4, 0, 8, 16), "BLACK SQUARE": (1, 4, 7, 10)}
    if name in blocks:
        x0, y0, x1, y1 = blocks[name]
        for y in range(y0, y1):
            for x in range(x0, x1): g[y][x] = 1
        return g
    return None

data = bytearray()
for code in range(256):
    ch = bytes([code]).decode("cp437") if code >= 32 else " "
    g = box(ch)
    if g is None:
        im = Image.new("L", (8, 16), 0)
        if ch.strip():
            ImageDraw.Draw(im).text((4, 8), ch, fill=255, font=mono, anchor="mm")
        g = [[1 if im.getpixel((x, y)) > 110 else 0 for x in range(8)] for y in range(16)]
    for row in g:
        data.append(sum(b << (7 - i) for i, b in enumerate(row)))
open(out + "/font.bin", "wb").write(data)

# ---------- preview: the menu drawn with that font on that wallpaper (2× scale, as Limine does at 1440p) ----------
def glyph_img(code, fg):
    im = Image.new("RGBA", (8 * 2, 16 * 2), (0, 0, 0, 0)); px = im.load()
    for y in range(16):
        b = data[code * 16 + y]
        for x in range(8):
            if b >> (7 - x) & 1:
                for dx in range(2):
                    for dy in range(2): px[x * 2 + dx, y * 2 + dy] = fg
    return im
pv = wall.copy().convert("RGBA")
M = 300; box_ = Image.new("RGBA", (W - 2 * M, H - 2 * M), (8, 8, 8, 200)); pv.alpha_composite(box_, (M, M))
def put(col, row, text, fg=(200, 200, 200, 255), bg=None):
    for i, ch in enumerate(text):
        x, y = M + (col + i) * 16, M + row * 32
        if bg: pv.alpha_composite(Image.new("RGBA", (16, 32), bg), (x, y))
        try: code = ch.encode("cp437")[0]
        except Exception: code = 63
        pv.alpha_composite(glyph_img(code, fg), (x, y))
cols = (W - 2 * M) // 16   # term_font_spacing: 0
title = "CachyOS  ·  monochrome"
put((cols - len(title)) // 2, 1, title, (255, 255, 255, 255))
help_ = "ARROWS Select   ENTER Boot   E Edit"
put((cols - len(help_)) // 2, 2, help_, (106, 106, 106, 255))
put(4, 4, "┌" + "─" * (cols - 10) + "┐", (90, 90, 90, 255))
items = ["CachyOS", "  linux-cachyos", "  linux-cachyos (fallback)", "  Snapshots"]
for i, t in enumerate(items):
    sel = i == 1
    put(4, 5 + i, "│", (90, 90, 90, 255)); put(cols - 5, 5 + i, "│", (90, 90, 90, 255))
    put(6, 5 + i, (" " + t).ljust(cols - 13), (11, 11, 11, 255) if sel else (200, 200, 200, 255), (236, 236, 236, 255) if sel else None)
put(4, 9, "└" + "─" * (cols - 10) + "┘", (90, 90, 90, 255))
put(6, 11, "Booting automatically in 5, press any key to stop the countdown...", (120, 120, 120, 255))
pv.convert("RGB").resize((W // 2, H // 2), Image.LANCZOS).save(out + "/preview.png")
print("ok", out)
