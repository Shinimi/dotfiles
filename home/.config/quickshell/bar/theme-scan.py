#!/usr/bin/env python3
# theme-scan.py: lists every icon theme, cursor theme and interface font installed, for Settings → Theme.
# Prints JSON: {"icons": [{id, name, previews[]}], "cursors": [{id, name, preview}], "fonts": [{family, kind}]}.
# Cursor previews (pointer, hand, text, busy) are drawn from the real Xcursor files into ~/.cache/qsbar/cursors.
# Made by Claude.
import json, os, re, struct, subprocess, sys

HOME = os.path.expanduser("~")
ROOTS = [os.path.join(HOME, ".icons"), os.path.join(HOME, ".local/share/icons"), "/usr/share/icons"]
CACHE = os.path.join(HOME, ".cache/qsbar/cursors")
SKIP = {"default", "hicolor", "locolor"}


def theme_dirs():
    seen = {}
    for root in ROOTS:
        if not os.path.isdir(root):
            continue
        for n in sorted(os.listdir(root)):
            p = os.path.join(root, n)
            if n not in seen and n not in SKIP and os.path.isdir(p):
                seen[n] = p
    return seen


def index(path):
    out = {}
    try:
        for line in open(os.path.join(path, "index.theme"), errors="ignore"):
            m = re.match(r"\s*(Name|Inherits|Directories)\s*=\s*(.*)", line)
            if m and m.group(1) not in out:
                out[m.group(1)] = m.group(2).strip()
    except OSError:
        pass
    return out


# ---------- icon themes: a few real icons from each, so you see the style
WANT = [["folder", "inode-directory"], ["user-home", "folder-home"], ["utilities-terminal", "terminal", "org.gnome.Terminal"],
        ["internet-web-browser", "web-browser", "firefox"], ["preferences-system", "systemsettings", "system-settings"],
        ["multimedia-audio-player", "audio-player", "spotify"]]


def icon_lookup(path):
    best = {}
    names = {n for group in WANT for n in group}
    for dp, _, files in os.walk(path, followlinks=True):
        size = 48 if re.search(r"(^|/)(48|48x48)(/|$)", dp) else 64 if "scalable" in dp else 32 if re.search(r"(^|/)(32|32x32)(/|$)", dp) else 0
        if "symbolic" in dp or size == 0:
            continue
        for f in files:
            stem, ext = os.path.splitext(f)
            if stem in names and ext in (".svg", ".png"):
                if size > best.get(stem, (0, ""))[0]:
                    best[stem] = (size, os.path.join(dp, f))
    return {k: v[1] for k, v in best.items()}


def icon_previews(name, themes, depth=0, found=None):
    found = found if found is not None else {}
    path = themes.get(name)
    if not path or depth > 3:
        return found
    hits = icon_lookup(path)
    for i, group in enumerate(WANT):
        if i not in found:
            for n in group:
                if n in hits and os.path.exists(hits[n]):
                    found[i] = hits[n]; break
    if len(found) < len(WANT):
        for parent in index(path).get("Inherits", "").split(","):
            parent = parent.strip()
            if parent and parent != "hicolor":
                icon_previews(parent, themes, depth + 1, found)
    return found


# ---------- cursor themes: read the Xcursor files and draw pointer · hand · text · busy side by side
CURSORS = [["left_ptr", "default", "arrow"], ["hand2", "pointer", "hand1"], ["xterm", "text", "ibeam"], ["watch", "wait", "progress", "left_ptr_watch"]]


def xcursor_image(path, want=32):
    data = open(path, "rb").read()
    if data[:4] != b"Xcur":
        return None
    hsize, _, ntoc = struct.unpack_from("<III", data, 4)
    toc = [struct.unpack_from("<III", data, hsize + i * 12) for i in range(ntoc)]
    imgs = [(sub, pos) for typ, sub, pos in toc if typ == 0xFFFD0002]
    if not imgs:
        return None
    sub, pos = min(imgs, key=lambda t: (abs(t[0] - want), -t[0]))
    w, h, xh, yh = struct.unpack_from("<IIII", data, pos + 16)
    px = data[pos + 36: pos + 36 + w * h * 4]
    from PIL import Image
    im = Image.frombuffer("RGBA", (w, h), px, "raw", "BGRA", 0, 1)
    return im


def cursor_preview(name, path):
    os.makedirs(CACHE, exist_ok=True)
    out = os.path.join(CACHE, name + ".png")
    src = os.path.join(path, "cursors")
    stamp = str(int(os.path.getmtime(src)))
    if os.path.exists(out) and open(out + ".stamp").read() == stamp if os.path.exists(out + ".stamp") else False:
        return out
    try:
        from PIL import Image
    except ImportError:
        return ""
    tiles = []
    for group in CURSORS:
        for n in group:
            f = os.path.join(src, n)
            if os.path.exists(f):
                try:
                    im = xcursor_image(f)
                except Exception:
                    im = None
                if im:
                    tiles.append(im.resize((48, 48), Image.LANCZOS) if im.size != (48, 48) else im)
                    break
    if not tiles:
        return ""
    sheet = Image.new("RGBA", (len(tiles) * 64 - 16, 48), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * 64, 0), t)
    sheet.save(out)
    open(out + ".stamp", "w").write(stamp)
    return out


# ---------- fonts: every family that can write English, minus symbol/script-only and duplicate variants
NOT_UI = re.compile(r"emoji|awesome|icomoon|music|math|symbol|\.pcf|ClearlyU|Syriac|Estrangelo|Serto|CJK|WenQuanYi|"
                    r"Nerd Font (Mono|Propo)$|Variable$|Compressed$|Condensed$|Outline$|Noto (Kufi|Naskh|Nastaliq|Rashi|Fangsong)", re.I)


def fonts():
    out = subprocess.run(["fc-list", ":lang=en:outline=true", "family", "spacing"], capture_output=True, text=True).stdout
    fams = {}
    for line in out.splitlines():
        fam, _, sp = line.partition(":spacing=")
        fam = fam.split(",")[0].strip().replace("\\-", "-")
        if not fam or NOT_UI.search(fam):
            continue
        mono = (sp.strip().isdigit() and int(sp) >= 90) or bool(re.search(r"Mono\b|Code\b|Hack$", fam))
        fams[fam] = fams.get(fam) or mono
    kind = lambda f, m: "mono" if m else "serif" if re.search(r"Serif|Times|Georgia|Garamond|Merriweather", f, re.I) else "sans"
    return [{"family": f, "kind": kind(f, m)} for f, m in sorted(fams.items(), key=lambda t: t[0].lower())]


def main():
    themes = theme_dirs()
    icons, cursors = [], []
    for name, path in themes.items():
        meta = index(path)
        if os.path.isdir(os.path.join(path, "cursors")):
            prev = cursor_preview(name, path)
            if prev:
                cursors.append({"id": name, "name": re.sub(r"\s+", " ", meta.get("Name", name).replace("-", " ")).strip(), "preview": prev})
        if "Directories" in meta:
            found = icon_previews(name, themes)
            if len(found) >= 3:
                icons.append({"id": name, "name": meta.get("Name", name), "previews": [found[i] for i in sorted(found)][:5]})
    json.dump({"icons": icons, "cursors": cursors, "fonts": fonts()}, sys.stdout)


main()
