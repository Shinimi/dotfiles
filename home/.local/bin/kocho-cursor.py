#!/usr/bin/env python3
# kocho-cursor.py – builds the "Kocho" cursor theme by recolouring capitaine-cursors-light:
# white body -> pale haori white with a faint pink blush, dark outline -> deep plum, accents -> wisteria.
# Output: ~/.local/share/icons/Kocho-cursors. Made by Claude.
import os, struct, shutil
SRC = "/usr/share/icons/capitaine-cursors-light"
DST = os.path.expanduser("~/.local/share/icons/Kocho-cursors")
DARK  = (28, 18, 44)      # outline: deep plum
LIGHT = (250, 238, 246)   # body: haori white, faintly pink
ACC   = (162, 138, 232)   # wisteria violet for coloured bits (busy spinner etc.)

def recolor(px):
    a = px >> 24
    if a == 0: return px
    r, g, b = (px >> 16) & 255, (px >> 8) & 255, px & 255
    # un-premultiply
    r, g, b = (min(255, c * 255 // a) for c in (r, g, b))
    sat = max(r, g, b) - min(r, g, b)
    l = (r * 299 + g * 587 + b * 114) / 255000
    if sat > 40:                               # coloured pixel: rainbow hue -> violet/pink/cyan wheel
        import colorsys
        hh = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)[0]
        wheel = [(162, 138, 232), (227, 158, 192), (242, 173, 148), (227, 158, 192), (127, 196, 227), (162, 138, 232)]
        x = hh * (len(wheel) - 1); i0 = int(x); f = x - i0; i1 = min(i0 + 1, len(wheel) - 1)
        nr, ng, nb = (int(wheel[i0][k] + (wheel[i1][k] - wheel[i0][k]) * f) for k in range(3))
    else:                                      # grey ramp: plum → haori white
        nr, ng, nb = (int(DARK[i] + (LIGHT[i] - DARK[i]) * l) for i in range(3))
    nr, ng, nb = (min(255, c * a // 255) for c in (nr, ng, nb))   # premultiply again
    return (a << 24) | (nr << 16) | (ng << 8) | nb

def convert(src, dst):
    d = bytearray(open(src, "rb").read())
    magic, hsize, ver, ntoc = struct.unpack_from("<4sIII", d, 0)
    for i in range(ntoc):
        typ, sub, pos = struct.unpack_from("<III", d, hsize + i * 12)
        if typ != 0xfffd0002: continue
        chsize, ctype, csub, cver, w, h, xh, yh, delay = struct.unpack_from("<IIIIIIIII", d, pos)
        off = pos + chsize
        n = w * h
        pixels = struct.unpack_from(f"<{n}I", d, off)
        struct.pack_into(f"<{n}I", d, off, *map(recolor, pixels))
    open(dst, "wb").write(d)

if os.path.exists(DST): shutil.rmtree(DST)
os.makedirs(DST + "/cursors")
for name in os.listdir(SRC + "/cursors"):
    s = os.path.join(SRC, "cursors", name); t = os.path.join(DST, "cursors", name)
    if os.path.islink(s): os.symlink(os.readlink(s), t)
    else: convert(s, t)
open(DST + "/index.theme", "w").write("[Icon Theme]\nName=Kocho-cursors\nComment=Shinobu Kocho cursor (recoloured Capitaine). Made by Claude.\nInherits=capitaine-cursors-light\n")
print(DST, len(os.listdir(DST + "/cursors")))
