#!/usr/bin/env python3
# wallmeta.py – for every wallpaper: thumbnail, colour palette, and a category (mono / dark / light / colour).
# Cached in ~/.cache/qs-wall-thumbs/meta.json; only new or changed pictures are analysed. Prints the JSON. Made by Claude.
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
W = os.path.expanduser("~/Pictures/wallpaper"); T = os.path.expanduser("~/.cache/qs-wall-thumbs")
os.makedirs(T, exist_ok=True); M = os.path.join(T, "meta.json")
try: meta = json.load(open(M))
except Exception: meta = {}
exts = (".png", ".jpg", ".jpeg", ".webp", ".mp4", ".webm", ".mkv", ".mov")
vids = (".mp4", ".webm", ".mkv", ".mov")   # live wallpapers: a frame from 1 s in stands in for the picture
files = sorted(f for f in os.listdir(W) if f.lower().endswith(exts) and os.path.isfile(os.path.join(W, f)))

def analyse(f):
    src = os.path.join(W, f); th = os.path.join(T, os.path.splitext(f)[0] + ".jpg"); mt = os.path.getmtime(src)
    old = meta.get(f)
    if old and old.get("mtime") == mt and os.path.exists(th): return f, old
    video = f.lower().endswith(vids)
    if not (os.path.exists(th) and os.path.getmtime(th) >= mt):
        if video:
            frame = th + ".frame.jpg"
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", "1", "-i", src, "-frames:v", "1", frame], capture_output=True)
            src_img = frame
        else: src_img = src + "[0]"
        subprocess.run(["magick", src_img, "-auto-orient", "-thumbnail", "640x360^", "-gravity", "center",
                        "-extent", "640x360", "-quality", "84", th], capture_output=True)
    # saturation + lightness (HSL means), and a 5-colour palette sorted dark → light
    st = subprocess.run(["magick", th, "-colorspace", "HSL", "-format", "%[fx:mean.g] %[fx:mean.b]", "info:"],
                        capture_output=True, text=True).stdout.split()
    sat, light = (float(st[0]), float(st[1])) if len(st) == 2 else (0, 0.5)
    pal = subprocess.run(["magick", th, "-resize", "96x54!", "-colors", "5", "-unique-colors", "-depth", "8", "txt:"],
                         capture_output=True, text=True).stdout
    cols = []
    for line in pal.splitlines()[1:]:
        h = line.split("#")[1][:6] if "#" in line else ""
        if h: cols.append("#" + h.lower())
    cols.sort(key=lambda c: sum(int(c[i:i+2], 16) for i in (1, 3, 5)))
    cat = "live" if video else "mono" if sat < 0.09 else ("dark" if light < 0.26 else ("light" if light > 0.62 else "colour"))
    return f, {"mtime": mt, "thumb": th, "sat": round(sat, 3), "light": round(light, 3), "palette": cols, "cat": cat}

with ThreadPoolExecutor(os.cpu_count() or 4) as ex:
    res = dict(ex.map(analyse, files))
json.dump(res, open(M, "w"))
out = [dict(path=os.path.join(W, f), name=os.path.splitext(f)[0], **{k: v for k, v in m.items() if k != "mtime"}) for f, m in res.items()]
json.dump(out, sys.stdout)
