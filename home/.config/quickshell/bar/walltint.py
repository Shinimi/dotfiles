#!/usr/bin/env python3
# walltint.py <image> – prints one accent colour for the image: its most colourful palette tone,
# brought to a mid lightness so a little of it reads on dark glass. Grey pictures give grey. Made by Claude.
import colorsys, subprocess, sys
out = subprocess.run(["magick", sys.argv[1] + "[0]", "-resize", "120x68!", "-colors", "6", "-unique-colors", "-depth", "8", "txt:"],
                     capture_output=True, text=True).stdout
best, score = (0.5, 0.5, 0.5), -1
for line in out.splitlines()[1:]:
    if "#" not in line: continue
    h = line.split("#")[1][:6]; r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    hh, l, s = colorsys.rgb_to_hls(r, g, b)
    sc = s * (1 - abs(l - 0.5) * 1.4)          # colourful and not near black/white
    if sc > score: best, score = (hh, l, s), sc
hh, l, s = best
r, g, b = colorsys.hls_to_rgb(hh, 0.55, min(s, 0.75))
print("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))
