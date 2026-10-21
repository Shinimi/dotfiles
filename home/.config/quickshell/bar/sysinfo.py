#!/usr/bin/env python3
# sysinfo.py defaults|storage|network|updates|avatars – JSON for the settings pages. Made by Claude.
import json, os, re, subprocess, sys, glob, configparser

def sh(cmd, t=8):
    try: return subprocess.run(cmd, capture_output=True, text=True, timeout=t).stdout
    except Exception: return ""

HOME = os.path.expanduser("~")

# ---- default apps -----------------------------------------------------------
CATS = [  # id, label, mime types to set, mime used to read the current one
    ("browser", "Web browser", ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"], "x-scheme-handler/https"),
    ("files", "File manager", ["inode/directory"], "inode/directory"),
    ("images", "Images", ["image/png", "image/jpeg", "image/webp", "image/gif"], "image/png"),
    ("video", "Videos", ["video/mp4", "video/x-matroska", "video/webm"], "video/mp4"),
    ("music", "Music", ["audio/mpeg", "audio/flac", "audio/ogg"], "audio/mpeg"),
    ("text", "Text editor", ["text/plain"], "text/plain"),
    ("pdf", "PDF documents", ["application/pdf"], "application/pdf"),
    ("archive", "Archives", ["application/zip", "application/x-7z-compressed", "application/x-tar"], "application/zip"),
]

def desktop_files():
    dirs = [os.path.join(HOME, ".local/share/applications"), "/usr/share/applications",
            "/var/lib/flatpak/exports/share/applications", os.path.join(HOME, ".local/share/flatpak/exports/share/applications")]
    seen = {}
    for d in dirs:
        for f in glob.glob(os.path.join(d, "*.desktop")):
            i = os.path.basename(f)
            if i in seen: continue
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            try: cp.read(f, encoding="utf-8")
            except Exception: continue
            if not cp.has_section("Desktop Entry"): continue
            e = cp["Desktop Entry"]
            if e.get("NoDisplay", "false").lower() == "true" or e.get("Hidden", "false").lower() == "true": continue
            seen[i] = {"id": i, "name": e.get("Name", i), "icon": e.get("Icon", ""),
                       "mime": [m for m in e.get("MimeType", "").split(";") if m]}
    return seen

def defaults():
    apps = desktop_files(); out = []
    for cid, label, mimes, probe in CATS:
        cur = sh(["xdg-mime", "query", "default", probe]).strip()
        opts = [a for a in apps.values() if any(m in a["mime"] for m in mimes)]
        opts.sort(key=lambda a: a["name"].lower())
        out.append({"id": cid, "label": label, "mimes": mimes, "current": cur,
                    "options": [{"id": a["id"], "name": a["name"], "icon": a["icon"]} for a in opts]})
    return out

# ---- storage ----------------------------------------------------------------
def storage():
    disks = []
    for l in sh(["df", "-B1", "--output=source,target,fstype,size,used,avail", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay"]).splitlines()[1:]:
        p = l.split()
        if len(p) < 6 or not p[0].startswith("/dev/"): continue
        if p[1].startswith(("/boot", "/var", "/srv", "/root", "/tmp")) and p[1] != "/": continue
        if any(d["source"] == p[0] and d["fs"] == "btrfs" for d in disks): continue  # btrfs subvolumes
        disks.append({"source": p[0], "mount": p[1], "fs": p[2], "size": int(p[3]), "used": int(p[4]), "free": int(p[5])})
    drives = []
    tree = sh(["busctl", "--system", "tree", "org.freedesktop.UDisks2"])
    for path in sorted(set(re.findall(r"/org/freedesktop/UDisks2/drives/\w+", tree))):
        g = lambda iface, prop: sh(["busctl", "--system", "get-property", "org.freedesktop.UDisks2", path, iface, prop]).strip()
        model = g("org.freedesktop.UDisks2.Drive", "Model").split('"')[1] if '"' in g("org.freedesktop.UDisks2.Drive", "Model") else ""
        size = g("org.freedesktop.UDisks2.Drive", "Size").split()[-1] if g("org.freedesktop.UDisks2.Drive", "Size") else "0"
        warn = g("org.freedesktop.UDisks2.NVMe.Controller", "SmartCriticalWarning")
        temp = g("org.freedesktop.UDisks2.NVMe.Controller", "SmartTemperature")
        if not model: continue
        drives.append({"model": model, "size": int(size or 0), "healthy": warn in ("as 0", ""),
                       "temp": int(temp.split()[-1]) - 273 if temp else -1})
    return {"mounts": disks, "drives": drives}

# ---- network ----------------------------------------------------------------
def network():
    devs = []
    for l in sh(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]).splitlines():
        d, t, st, con = (l.split(":") + ["", "", "", ""])[:4]
        if t in ("loopback", "bridge", "tun") or d.startswith(("veth", "docker", "virbr")): continue
        info = {"device": d, "type": t, "state": st, "connection": con}
        for k in sh(["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "device", "show", d]).splitlines():
            key, _, val = k.partition(":")
            key = key.split("[")[0]
            info.setdefault(key, val)
        try: info["speed"] = int(open(f"/sys/class/net/{d}/speed").read().strip())
        except Exception: info["speed"] = 0
        devs.append(info)
    wifi = []
    if any(d["type"] == "wifi" for d in devs):
        for l in sh(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"], 12).splitlines():
            p = l.split(":")
            if len(p) >= 4 and p[1]: wifi.append({"active": p[0] == "*", "ssid": p[1], "signal": int(p[2] or 0), "secure": p[3] not in ("", "--")})
    return {"devices": devs, "wifi": wifi, "wifiOn": sh(["nmcli", "radio", "wifi"]).strip() == "enabled"}

# ---- updates ----------------------------------------------------------------
def updates():
    repo = [l.split()[:4] for l in sh(["checkupdates"], 40).splitlines() if l.strip()]
    aur = [l.split()[:4] for l in sh(["yay", "-Qua"], 40).splitlines() if l.strip()]
    f = lambda rows, src: [{"name": r[0], "from": r[1] if len(r) > 1 else "", "to": r[3] if len(r) > 3 else "", "src": src} for r in rows]
    return f(repo, "repo") + f(aur, "AUR")

# ---- avatar candidates --------------------------------------------------------
def avatars():
    pics = []
    for d in ["Pictures/PFP/**", "Pictures", "Pictures/Artworks"]:
        for f in sorted(glob.glob(os.path.join(HOME, d, "*"), recursive=True)):
            if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp")) and f not in pics: pics.append(f)
    return pics[:80]

# ---- set a default app: sysinfo.py setdefault <category> <desktop-id> ----------------------
def setdefault():
    cat, app = sys.argv[2], sys.argv[3]
    for cid, _, mimes, _ in CATS:
        if cid == cat:
            subprocess.run(["xdg-mime", "default", app] + mimes)
            if cid == "browser": subprocess.run(["xdg-settings", "set", "default-web-browser", app], capture_output=True)
            return {"ok": True}
    return {"ok": False}

cmd = sys.argv[1] if len(sys.argv) > 1 else ""
fn = {"defaults": defaults, "storage": storage, "network": network, "updates": updates, "avatars": avatars, "setdefault": setdefault}.get(cmd)
print(json.dumps(fn() if fn else {"error": "unknown command"}))
