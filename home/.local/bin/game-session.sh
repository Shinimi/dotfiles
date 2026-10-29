#!/usr/bin/env bash
# game-session.sh start <window-class> [window-address] | stop – called by gamemode.sh. Records each game session for the
# control center's Games page: what, when, how long, peak CPU/GPU temperature, average GPU load and (with MangoHud) FPS.
# Sessions are lines of JSON in ~/.local/state/game-sessions.jsonl. Made by Claude.
R="${XDG_RUNTIME_DIR:-/tmp}/game-session"; LOG="$HOME/.local/state/game-sessions.jsonl"; ML="$HOME/.local/state/mangohud-logs"
mkdir -p "$HOME/.local/state" "$ML"
case "$1" in
  start)
    [ -e "$R.info" ] && exit 0
    title=$(hyprctl clients -j | python3 -I -c "import json,sys;a=sys.argv[1];print(next((c['title'] for c in json.load(sys.stdin) if c['address']==a),''))" "${3:-}" 2>/dev/null)
    printf '%s\n%s\n%s\n' "$(date +%s)" "${2:-}" "$title" > "$R.info"
    : > "$R.samples"
    (   # every 5 s while the game runs: CPU °C, GPU °C, GPU busy %
      g=""; for d in /sys/class/drm/card*/device; do [ "$(cat $d/vendor)" = 0x1002 ] && { g=$d; break; }; done; h=$(echo $g/hwmon/hwmon*)
      c=$(echo /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input)
      while [ -e "$R.info" ]; do
        echo "$(( $(cat $c) / 1000 )) $(( $(cat $h/temp1_input) / 1000 )) $(cat $g/gpu_busy_percent)" >> "$R.samples"; sleep 5
      done
    ) >/dev/null 2>&1 &
    ;;
  stop)
    [ -e "$R.info" ] || exit 0
    { read -r t0; read -r cls; read -r title; } < "$R.info"; rm -f "$R.info"
    python3 -I - "$t0" "$cls" "$title" "$R.samples" "$LOG" "$ML" "$HOME/.local/share/Steam" <<'PY'
import sys, os, re, json, time, glob
t0, cls, title, samples, log, ml, steam = sys.argv[1:]
t0 = int(t0); t1 = int(time.time()); mins = round((t1 - t0) / 60, 1)
if mins < 1: sys.exit()                      # a launcher flash, not a session
m = re.match(r"steam_app_(\d+)", cls); gid = m.group(1) if m else cls
name = title or cls
if m:   # the real name from Steam's manifest
    for f in glob.glob(steam + "/steamapps/appmanifest_%s.acf" % gid) + glob.glob("/mnt/games/*/steamapps/appmanifest_%s.acf" % gid):
        n = re.search(r'"name"\s+"([^"]+)"', open(f, errors="ignore").read())
        if n: name = n.group(1); break
rows = []
try: rows = [list(map(int, l.split())) for l in open(samples) if len(l.split()) == 3]
except Exception: pass
s = {"id": gid, "name": name, "start": t0, "end": t1, "minutes": mins,
     "cpuPeak": max((r[0] for r in rows), default=0), "gpuPeak": max((r[1] for r in rows), default=0),
     "gpuLoad": round(sum(r[2] for r in rows) / len(rows)) if rows else 0, "fps": 0}
# MangoHud's log for this session (if the overlay was loaded): average FPS
logs = [f for f in glob.glob(ml + "/*.csv") if os.path.getmtime(f) >= t0]
if logs:
    f = max(logs, key=os.path.getmtime); fps = []
    lines = open(f, errors="ignore").read().splitlines()
    hdr = next((i for i, l in enumerate(lines) if l.startswith("fps")), None)
    if hdr is not None:
        for l in lines[hdr + 1:]:
            try: fps.append(float(l.split(",")[0]))
            except Exception: pass
    if fps: s["fps"] = round(sum(fps) / len(fps))
open(log, "a").write(json.dumps(s) + "\n")
for old in sorted(glob.glob(ml + "/*.csv"), key=os.path.getmtime)[:-20]: os.remove(old)   # keep the last 20 logs
PY
    rm -f "$R.samples" ;;
esac
