#!/usr/bin/env python3
# gamestats.py – the control center's Games page as JSON: this week (per day, per game) from the sessions game mode
# records (~/.local/state/game-sessions.jsonl), the latest sessions with temperatures and FPS, and all-time hours from
# Steam itself so the page is never empty. Made by Claude.
import json, os, subprocess, time, datetime
H = os.path.expanduser("~")
LOG = H + "/.local/state/game-sessions.jsonl"
here = os.path.dirname(os.path.abspath(__file__))

try: lib = json.loads(subprocess.run([here + "/games.sh"], capture_output=True, text=True, timeout=20).stdout)
except Exception: lib = []
by_id = {g["id"]: g for g in lib}

sessions = []
try:
    for l in open(LOG):
        try: sessions.append(json.loads(l))
        except Exception: pass
except FileNotFoundError: pass

today = datetime.date.today()
days = [today - datetime.timedelta(days=i) for i in range(6, -1, -1)]
week_start = time.mktime(days[0].timetuple())
week = [s for s in sessions if s["start"] >= week_start]
per_day = {d: 0.0 for d in days}
for s in week:
    d = datetime.date.fromtimestamp(s["start"])
    if d in per_day: per_day[d] += s["minutes"]

def cover(i): return by_id.get(i, {}).get("cover", "")

top = {}
for s in week:
    t = top.setdefault(s["id"], {"id": s["id"], "name": s["name"], "cover": cover(s["id"]), "minutes": 0, "sessions": 0})
    t["minutes"] += s["minutes"]; t["sessions"] += 1
top = sorted(top.values(), key=lambda t: -t["minutes"])[:4]

def when(ts):
    d = datetime.date.fromtimestamp(ts); t = time.strftime("%H:%M", time.localtime(ts))
    return ("Today " if d == today else "Yesterday " if d == today - datetime.timedelta(days=1) else d.strftime("%a %d %b ")) + t

recent = [dict(s, cover=cover(s["id"]), when=when(s["start"])) for s in sorted(sessions, key=lambda s: -s["start"])[:5]]
all_time = sorted(({"id": g["id"], "name": g["name"], "cover": g["cover"], "minutes": g["minutes"]} for g in lib if g.get("minutes")), key=lambda g: -g["minutes"])[:4]

json.dump({
    "week": {"minutes": round(sum(s["minutes"] for s in week)), "sessions": len(week),
             "days": [{"d": d.strftime("%a")[:2], "minutes": round(per_day[d]), "today": d == today} for d in days],
             "peakGpu": max((s["gpuPeak"] for s in week), default=0), "avgFps": round(sum(s["fps"] for s in week if s["fps"]) / max(1, len([s for s in week if s["fps"]])))},
    "top": top, "recent": recent, "allTime": all_time,
    "allTimeHours": round(sum(g.get("minutes", 0) for g in lib) / 60), "installed": len(lib), "recorded": len(sessions),
}, os.sys.stdout)
