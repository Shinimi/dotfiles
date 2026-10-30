#!/usr/bin/env python3
# recolor.py <in> <out> [purple|forest|mint]: turns a file of the black/monochrome theme into Niri's colours.
# purple (default): each grey mapped to the purple palette step of the same brightness, so every app keeps exactly
# the design it has in Hyprland, only in purple.
# Greys only (real colours like the red for errors stay): text → near-white with a hint of mint, the light accent grey
# → mint, dim greys → muted teal, backgrounds → deep teal. Knows every colour notation the themed apps use:
# #rrggbb(aa), rgb()/rgba(), Qt "r,g,b", JSON [r, g, b], spicetify "key = rrggbb", kitty "_rrggbb". Made by Claude.
import colorsys, json, re, sys

HUE = 170 / 360


# Everforest Dark Soft (sainnhe/everforest): darkest → lightest, by the brightness of the grey it replaces
FOREST = [(0.055, "293136"), (0.09, "333C43"), (0.13, "3A464C"), (0.17, "434F55"), (0.22, "4D5960"), (0.30, "555F66"),
          (0.40, "5D6B66"), (0.50, "7A8478"), (0.62, "859289"), (0.82, "9DA9A0"), (0.905, "A7C080"), (9, "D3C6AA")]


PURPLE = [(0.055, "100D16"), (0.09, "16121F"), (0.13, "1D1828"), (0.17, "241E32"), (0.22, "2C253D"), (0.30, "372F4B"),
          (0.40, "453B5D"), (0.50, "5E5478"), (0.62, "7D7398"), (0.82, "A49CBD"), (0.905, "B392F0"), (9, "ECE6F7")]


def ramp(steps, r, g, b):
    if max(r, g, b) - min(r, g, b) > 14 or (r, g, b) == (0, 0, 0):
        return r, g, b
    L = (r + g + b) / 3 / 255
    h = next(c for top, c in steps if L < top)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def purple(r, g, b): return ramp(PURPLE, r, g, b)


def forest(r, g, b):
    if max(r, g, b) - min(r, g, b) > 14 or (r, g, b) == (0, 0, 0):
        return r, g, b
    L = (r + g + b) / 3 / 255
    h = next(c for top, c in FOREST if L < top)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def mint(r, g, b):
    if max(r, g, b) - min(r, g, b) > 14 or (r, g, b) == (0, 0, 0):
        return r, g, b                                   # a real colour (or pure black): leave it
    L = (r + g + b) / 3 / 255
    if L >= 0.905:   h, s, l = HUE, 0.22, L                          # text
    elif L >= 0.82:  h, s, l = 172 / 360, 0.50, 0.66 + (L - 0.82)    # the accent (#e0e0e0 & co) → mint #81d5cb-ish
    elif L >= 0.55:  h, s, l = HUE, 0.26, L                          # dim text, secondary accents
    elif L >= 0.20:  h, s, l = HUE, 0.20, L                          # borders, mid surfaces
    else:            h, s, l = HUE, 0.32, L * 1.05                   # backgrounds → deep teal
    rr, gg, bb = colorsys.hls_to_rgb(h, min(l, 0.97), s)
    return round(rr * 255), round(gg * 255), round(bb * 255)


hx = lambda c: "%02x%02x%02x" % c


def sub_hex(m):
    t = m.group(2); c = mint(int(t[0:2], 16), int(t[2:4], 16), int(t[4:6], 16))
    out = hx(c)
    return m.group(1) + (out.upper() if t.isupper() else out) + (m.group(3) or "")


def recolor(text, path):
    if path.endswith("manifest.json"):                   # browser theme: colours are [r, g, b] lists
        d = json.loads(text)
        for k, v in d.get("theme", {}).get("colors", {}).items():
            d["theme"]["colors"][k] = list(mint(*v[:3])) + v[3:]
        d["name"] = "Niri (local)"; d["description"] = "Niri browser theme (purple). Made by Claude."
        return json.dumps(d, indent=2) + "\n"
    text = re.sub(r"(#)([0-9a-fA-F]{6})([0-9a-fA-F]{2})?\b", sub_hex, text)
    text = re.sub(r"(\b_)([0-9a-fA-F]{6})()\b", sub_hex, text)                                # kitty {fmt.fg._555555}
    text = re.sub(r"(^[\w-]+\s*=\s*)([0-9a-fA-F]{6})()\s*$", sub_hex, text, flags=re.M)        # spicetify color.ini
    text = re.sub(r"(rgba?\(\s*)(\d+)\s*,\s*(\d+)\s*,\s*(\d+)",
                  lambda m: m.group(1) + "%d,%d,%d" % mint(int(m.group(2)), int(m.group(3)), int(m.group(4))), text)
    text = re.sub(r"^([A-Za-z]+=)(\d+),(\d+),(\d+)$",                                           # Qt .colors
                  lambda m: m.group(1) + "%d,%d,%d" % mint(int(m.group(2)), int(m.group(3)), int(m.group(4))), text, flags=re.M)
    return text


if __name__ == "__main__":
    src, dst = sys.argv[1:3]
    pal = sys.argv[3] if len(sys.argv) > 3 else "purple"
    if pal != "mint":
        mint = {"purple": purple, "forest": forest}[pal]   # (the functions above look the mapping up by this name)
    out = recolor(open(src).read(), src)
    name = {"purple": "Purple", "forest": "Everforest"}.get(pal, "Mint")
    out = out.replace("Monochrome", name).replace("monochrome", name.lower())
    open(dst, "w").write(out)
