#!/usr/bin/env python3
# pkgwatch.py [--notify] – Settings → Packages as JSON: what changed this week (from /var/log/pacman.log), the biggest
# packages, leftovers nothing needs (orphans), AUR packages and the download cache. --notify sends the weekly summary
# as a notification instead (pkgwatch.timer, Mondays). Made by Claude.
import json, os, re, subprocess, sys, datetime

def run(*a):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=30).stdout
    except Exception: return ""

week_ago = datetime.datetime.now().astimezone() - datetime.timedelta(days=7)
changes, counts = [], {"upgraded": 0, "installed": 0, "removed": 0}
pat = re.compile(r"^\[([^\]]+)\] \[ALPM\] (upgraded|installed|removed) (\S+) \((.+)\)$")
try:
    for line in open("/var/log/pacman.log", errors="ignore"):
        m = pat.match(line.strip())
        if not m: continue
        try: t = datetime.datetime.fromisoformat(m.group(1))
        except ValueError: continue
        if t < week_ago: continue
        counts[m.group(2)] += 1
        changes.append({"when": t.strftime("%a %d %b"), "what": m.group(2), "name": m.group(3), "ver": m.group(4)})
except FileNotFoundError: pass

def size(s):   # expac's "%m" is bytes
    return int(s) if s.isdigit() else 0
sizes = []
for l in run("expac", "-Q", "%n\t%m").splitlines():
    n, _, b = l.partition("\t"); sizes.append((n, size(b)))
sizes.sort(key=lambda x: -x[1])
total = sum(b for _, b in sizes)

orph = [o for o in run("pacman", "-Qdtq").split() if o]
orph_size = sum(b for n, b in sizes if n in set(orph))
aur = [a for a in run("pacman", "-Qmq").split() if a]
cache = 0
for root, _, files in os.walk("/var/cache/pacman/pkg"):
    for f in files:
        try: cache += os.path.getsize(os.path.join(root, f))
        except OSError: pass

data = {
    "counts": counts, "changes": changes[::-1][:40], "installed": len(sizes), "explicit": len(run("pacman", "-Qeq").split()),
    "totalBytes": total, "biggest": [{"name": n, "bytes": b} for n, b in sizes[:8]],
    "orphans": orph, "orphanBytes": orph_size, "aur": aur, "cacheBytes": cache,
}
if "--notify" in sys.argv:
    gb = lambda b: f"{b / 1e9:.1f} GB"
    body = (f"{counts['upgraded']} updated, {counts['installed']} added, {counts['removed']} removed this week.\n"
            + (f"{len(orph)} leftover packages ({gb(orph_size)}) can go. " if orph else "")
            + f"Download cache: {gb(cache)}.")
    subprocess.run(["notify-send", "-a", "Packages", "-i", "system-software-update", "Your week in packages", body])
else:
    json.dump(data, sys.stdout)
