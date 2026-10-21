#!/usr/bin/env python3
# recolor-theme.py – swaps the Tokyo Night palette for the Shinobu Kochō palette in config files.
# Usage: recolor-theme.py FILE...   (keeps FILE.before-shinobu once). Made by Claude.
import re, sys, os, shutil
HEX = {  # tokyo -> shinobu
 "1a1b26":"1a1726","16161e":"13111c","15161e":"120f19","1f2335":"221d30","24283b":"252033","292e42":"2d2640",
 "414868":"4a3f63","545c7e":"6d6189","565f89":"7d7299","a9b1d6":"c9bddf","c0caf5":"ece4f6","e0e6ff":"f4eeff",
 "7aa2f7":"b69cf0","8db0ff":"cbb4ff","bb9af7":"e49bd8","c7a9ff":"f2b5e4","9d7cd8":"c58bd0","7dcfff":"8fd3e0",
 "a4daff":"b0e4ee","73daca":"7fcfc4","9ece6a":"9fdcc0","9fe044":"bfe9d4","e0af68":"f0c98a","faba4a":"f6dcaa",
 "f7768e":"f27a9e","ff899d":"f79ab6","ff9e64":"f5a98a","db4b4b":"d9507a","283457":"3b2f55","2e3c64":"433463",
 "3d59a1":"6b52a8","ff9eb0":"f7a1bd","8fb0ff":"c9b2ff",
}
DEC = {  # Qt.rgba(r, g, b, …) triples
 "0.48, 0.64, 0.97":"0.71, 0.61, 0.94", "0.62, 0.81, 0.42":"0.62, 0.86, 0.75", "0.97, 0.46, 0.56":"0.95, 0.48, 0.62",
 "0.88, 0.69, 0.41":"0.94, 0.79, 0.54", "0.086, 0.086, 0.118":"0.075, 0.067, 0.11", "0.102, 0.106, 0.149":"0.102, 0.09, 0.149",
 "0.141, 0.157, 0.231":"0.145, 0.125, 0.2",
}
RGB = {  # "r, g, b" / "r,g,b" decimal 0-255 (KDE, chrome manifest, hyprlock rgb())
 (26,27,38):(26,23,38),(22,22,30):(19,17,28),(31,32,46):(34,29,48),(36,40,59):(37,32,51),(41,46,66):(45,38,64),
 (31,35,53):(34,29,48),(65,72,104):(74,63,99),(86,95,137):(125,114,153),(169,177,214):(201,189,223),
 (192,202,245):(236,228,246),(122,162,247):(182,156,240),(187,154,247):(228,155,216),(125,207,255):(143,211,224),
 (158,206,106):(159,220,192),(224,175,104):(240,201,138),(247,118,142):(242,122,158),(61,89,161):(107,82,168),
 (40,52,87):(59,47,85),(87,108,177):(182,156,240),
}
hexre = re.compile(r'(?<![0-9a-fA-F])([0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)(?![0-9a-fA-F])')
def hexsub(m, text):
    h = m.group(1); low = h.lower(); up = h.isupper() and any(c.isalpha() for c in h)
    def conv(x): r = HEX.get(x.lower()); return None if r is None else (r.upper() if up else r)
    if len(h) == 6:
        r = conv(h); return r if r else h
    before = text[max(0, m.start() - 1):m.start()]
    if before == "#":      # Qt/CSS #AARRGGBB
        r = conv(h[2:]); return h[:2] + r if r else h
    r = conv(h[:6]); return r + h[6:] if r else h   # rgba(RRGGBBAA)
def rgbsub(s):
    def f(m):
        t = tuple(int(x) for x in re.split(r'\s*,\s*', m.group(2)))
        return m.group(1) + ", ".join(map(str, RGB[t])) if t in RGB else m.group(0)
    return re.sub(r'([\[(=]\s*)(\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3})(?=\s*[\])\n,;])', lambda m: (m.group(1) + (",".join(map(str, RGB[tuple(int(x) for x in re.split(r"\s*,\s*", m.group(2)))])) if tuple(int(x) for x in re.split(r"\s*,\s*", m.group(2))) in RGB else m.group(2))), s)
for p in sys.argv[1:]:
    if not os.path.isfile(p): continue
    s = open(p, encoding="utf-8").read(); o = s
    s = hexre.sub(lambda m: hexsub(m, s), s)
    for a, b in DEC.items(): s = s.replace(a, b)
    s = rgbsub(s)
    if s != o:
        if not os.path.exists(p + ".before-shinobu"): shutil.copy2(p, p + ".before-shinobu")
        open(p, "w", encoding="utf-8").write(s); print("recoloured", p)
