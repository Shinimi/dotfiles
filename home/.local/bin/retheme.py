#!/usr/bin/env python3
# retheme.py FROM TO FILE...  – swaps one palette for another in config files (hex, rgba hex, Qt.rgba, r,g,b).
# Palettes: tokyo, shinobu1, shinobu (current). Backs each file up once as FILE.before-<TO>. Made by Claude.
import re, sys, os, shutil
ROLES = ["bg","deep","deeper","bg2","surface","hl","line","line2","muted","fgdim","fg","fgbright",
         "primary","primary2","secondary","secondary2","mid","cyan","cyan2","cyan3","green","green2",
         "yellow","yellow2","red","red2","peach","red3","sel","sel2","selstrong","pink3","primary3"]
P = {
 "tokyo":    "1a1b26 16161e 15161e 1f2335 24283b 292e42 414868 545c7e 565f89 a9b1d6 c0caf5 e0e6ff 7aa2f7 8db0ff bb9af7 c7a9ff 9d7cd8 7dcfff a4daff 73daca 9ece6a 9fe044 e0af68 faba4a f7768e ff899d ff9e64 db4b4b 283457 2e3c64 3d59a1 ff9eb0 8fb0ff",
 "shinobu1": "1a1726 13111c 120f19 221d30 252033 2d2640 4a3f63 6d6189 7d7299 c9bddf ece4f6 f4eeff b69cf0 cbb4ff e49bd8 f2b5e4 c58bd0 8fd3e0 b0e4ee 7fcfc4 9fdcc0 bfe9d4 f0c98a f6dcaa f27a9e f79ab6 f5a98a d9507a 3b2f55 433463 6b52a8 f7a1bd c9b2ff",
 "mono":     "111111 0b0b0b 080808 161616 1c1c1c 242424 3a3a3a 555555 7a7a7a c8c8c8 eaeaea f5f5f5 e0e0e0 ffffff b0b0b0 cfcfcf a0a0a0 c4c4c4 dcdcdc bdbdbd c8c8c8 e2e2e2 d6d6d6 ececec cf6b6b dd8f8f c0c0c0 b05050 2a2a2a 333333 4a4a4a d8d8d8 f0f0f0",
 "shinobu":  "13121c 0d0c13 0a0910 1b1928 221f33 2a2640 403a5c 5f5878 807a9c cfc8e2 efeaf8 f7f4fc a28ae8 bba8f2 e39ec0 f0b9d3 b884d6 7fc4e3 a5d8ee 6fb8d6 8fd6b8 b5e6d0 eec48e f5d8aa ec6f8f f390a8 f2ad94 c94a6c 2f2950 3a3360 6a58b8 f2a9c6 b5a2f2",
}
P = {k: v.split() for k, v in P.items()}
src, dst = P[sys.argv[1]], P[sys.argv[2]]
HEX = dict(zip(src, dst))
rgb = lambda h: tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
SRC_RGB = [(rgb(a), rgb(b)) for a, b in zip(src, dst)]
def nearest(t, tol):
    best = min(SRC_RGB, key=lambda p: sum((x - y) ** 2 for x, y in zip(p[0], t)))
    return best[1] if sum((x - y) ** 2 for x, y in zip(best[0], t)) <= tol * tol else None
hexre = re.compile(r'(?<![0-9a-fA-F])([0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)(?![0-9a-fA-F])')
def hexsub(m, text):
    h = m.group(1); up = h.isupper() and any(c.isalpha() for c in h)
    def conv(x): r = HEX.get(x.lower()); return None if r is None else (r.upper() if up else r)
    if len(h) == 6: r = conv(h); return r if r else h
    if text[max(0, m.start() - 1):m.start()] == "#": r = conv(h[2:]); return h[:2] + r if r else h
    r = conv(h[:6]); return r + h[6:] if r else h
def decsub(m):   # Qt.rgba(0.48, 0.64, 0.97, …)
    t = tuple(round(float(x) * 255) for x in m.group(2).split(","))
    n = nearest(t, 6)
    return m.group(1) + ", ".join(f"{c/255:.2f}".rstrip("0").rstrip(".") if False else f"{c/255:.2f}" for c in n) if n else m.group(0)
def rgbsub(m):   # 26,27,38  /  [22, 22, 30]
    t = tuple(int(x) for x in re.split(r"\s*,\s*", m.group(2)))
    if max(t) > 255: return m.group(0)
    n = nearest(t, 4)
    sep = ", " if ", " in m.group(2) else ","
    return m.group(1) + sep.join(map(str, n)) if n else m.group(0)
for p in sys.argv[3:]:
    if not os.path.isfile(p): continue
    try: s = open(p, encoding="utf-8").read()
    except UnicodeDecodeError: continue
    o = s
    s = hexre.sub(lambda m: hexsub(m, s), s)
    s = re.sub(r'(Qt\.rgba\(\s*)(0?\.\d+\s*,\s*0?\.\d+\s*,\s*0?\.\d+)', decsub, s)
    s = re.sub(r'([\[(=]\s*)(\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3})(?=\s*[\])\n,;])', rgbsub, s)
    s = re.sub(r'(SetBackground(?:Top|Bottom)Color\()(0?\.\d+, 0?\.\d+, 0?\.\d+)', decsub, s)
    if s != o:
        b = p + ".before-" + sys.argv[2]
        if not os.path.exists(b): shutil.copy2(p, b)
        open(p, "w", encoding="utf-8").write(s); print("recoloured", p)
