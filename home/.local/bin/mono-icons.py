#!/usr/bin/env python3
# mono-icons.py – builds ~/.local/share/icons/Tela-mono: Tela-circle-black(-dark) with every colour turned grey. Made by Claude.
import os, re, shutil, sys
SRC = ["/usr/share/icons/Tela-circle-black", "/usr/share/icons/Tela-circle-black-dark"]
DST = os.path.expanduser("~/.local/share/icons/Tela-mono")
hexre = re.compile(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b')
rgbre = re.compile(r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
def g(r, gg, b):
    l = int(0.2126 * r + 0.7152 * gg + 0.0722 * b)
    l = int(40 + l * 0.8)                       # lift darks a bit, keep highlights soft
    return f"#{l:02x}{l:02x}{l:02x}"
def fix_hex(m):
    h = m.group(1)
    if len(h) == 3: h = "".join(c * 2 for c in h)
    return g(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
def conv(path):
    try: s = open(path, encoding="utf-8").read()
    except Exception: return
    s = hexre.sub(fix_hex, s); s = rgbre.sub(lambda m: g(*map(int, m.groups())), s)
    open(path, "w", encoding="utf-8").write(s)
if os.path.exists(DST): shutil.rmtree(DST)
shutil.copytree(SRC[0], DST, symlinks=True)
# the -dark variant overrides some dirs (light symbolic icons for dark panels)
for root, dirs, files in os.walk(SRC[1]):
    rel = os.path.relpath(root, SRC[1]); os.makedirs(os.path.join(DST, rel), exist_ok=True)
    for f in files:
        s, d = os.path.join(root, f), os.path.join(DST, rel, f)
        if os.path.islink(d) or os.path.exists(d): os.remove(d)
        if os.path.islink(s): os.symlink(os.readlink(s), d)
        else: shutil.copy2(s, d)
n = 0
for root, dirs, files in os.walk(DST):
    for f in files:
        p = os.path.join(root, f)
        if f.endswith(".svg") and not os.path.islink(p): conv(p); n += 1
it = os.path.join(DST, "index.theme"); t = open(it).read()
t = re.sub(r"^Name=.*$", "Name=Tela-mono", t, flags=re.M); t = re.sub(r"^Inherits=.*$", "Inherits=Papirus-Dark,hicolor,breeze-dark", t, flags=re.M)
open(it, "w").write(t)
cache = os.path.join(DST, "icon-theme.cache")
if os.path.exists(cache): os.remove(cache)
os.system(f"gtk-update-icon-cache -q -f '{DST}' 2>/dev/null")
print(DST, n, "icons")
