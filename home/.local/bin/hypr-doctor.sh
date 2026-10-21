#!/usr/bin/env bash
# hypr-doctor.sh [--fix] – brings back desktop pieces that died (bar, wallpaper, idle/lock, clipboard history,
# password prompts). A timer runs it quietly every 2 minutes; SUPER+SHIFT+R runs it with --fix (reload + report).
# Made by Claude.
pidof Hyprland >/dev/null || exit 0
fix=0; [ "$1" = --fix ] && fix=1
fixed=()
# launch through Hyprland so the program outlives this script (and the systemd timer that runs it)
start() { hyprctl dispatch "hl.dsp.exec_cmd(\"$*\")" >/dev/null; }

# top bar (run.sh restarts qs by itself; only start the wrapper if it's gone)
pgrep -f "[q]uickshell/bar/run.sh" >/dev/null || { start "$HOME/.config/quickshell/bar/run.sh"; fixed+=("bar"); }
# wallpaper
pgrep -x hyprpaper >/dev/null || { start hyprpaper; fixed+=("wallpaper"); }
# auto-lock (skipped while "keep awake" is on)
[ -e "$XDG_RUNTIME_DIR/keep-awake" ] || pgrep -x hypridle >/dev/null || { start hypridle; fixed+=("auto-lock"); }
# clipboard history
pgrep -f "[w]l-paste --type text" >/dev/null || { start wl-paste --type text --watch cliphist store; fixed+=("clipboard"); }
pgrep -f "[w]l-paste --type image" >/dev/null || { start wl-paste --type image --watch cliphist store; fixed+=("clipboard images"); }
# password prompts
systemctl --user is-active -q hyprpolkitagent || { systemctl --user restart hyprpolkitagent; fixed+=("password prompts"); }

# ---- night light schedule (only acts when the evening/morning time is crossed, so manual toggles stick)
cfg=$(python3 -I -c "import json,os;d=json.load(open(os.path.expanduser('~/.config/hypr/settings.json')));print(int(d.get('night_auto',False)),int(d.get('night_from',21)),int(d.get('night_to',7)),int(d.get('night_temp',4500)))" 2>/dev/null)
read -r n_auto n_from n_to n_temp <<<"${cfg:-0 21 7 4500}"
if [ "$n_auto" = 1 ]; then
  h=$(date +%-H); if [ "$n_from" -gt "$n_to" ]; then { [ "$h" -ge "$n_from" ] || [ "$h" -lt "$n_to" ]; } && ph=night || ph=day
  else { [ "$h" -ge "$n_from" ] && [ "$h" -lt "$n_to" ]; } && ph=night || ph=day; fi
  P="$XDG_RUNTIME_DIR/night-phase"
  if [ "$(cat "$P" 2>/dev/null)" != "$ph" ]; then
    echo "$ph" > "$P"
    if [ $ph = night ] && ! pgrep -x hyprsunset >/dev/null; then start "hyprsunset -t $n_temp"
    elif [ $ph = day ] && pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; fi
  fi
fi

# ---- warnings: too hot / disk nearly full (at most once an hour each)
warn() { local f="$XDG_RUNTIME_DIR/warned-$1"; [ -n "$(find "$f" -mmin -60 2>/dev/null)" ] && return; touch "$f"; notify-send -u critical -a "Desktop doctor" "$2" "$3"; }
for hw in /sys/class/hwmon/hwmon*; do
  case "$(cat "$hw/name" 2>/dev/null)" in
    k10temp) t=$(( $(cat "$hw/temp1_input" 2>/dev/null || echo 0) / 1000 )); [ "$t" -ge 90 ] && warn cpu "CPU is at ${t}°C" "Something is working it hard – check the task manager (Ctrl+Alt+Delete)." ;;
    amdgpu)  t=$(( $(cat "$hw/temp2_input" 2>/dev/null || cat "$hw/temp1_input" 2>/dev/null || echo 0) / 1000 )); [ "$t" -ge 100 ] && warn gpu "GPU hotspot is at ${t}°C" "Check the fans / case airflow." ;;
  esac
done
for mp in / "$HOME/Games/InternalDrive"; do
  u=$(df --output=pcent "$mp" 2>/dev/null | tail -1 | tr -dc 0-9); [ -n "$u" ] && [ "$u" -ge 92 ] && warn "disk$(echo "$mp" | tr / _)" "$mp is ${u}% full" "Free some space so updates and games keep working."
done

if [ $fix = 1 ]; then
  hyprctl reload >/dev/null
  if [ ${#fixed[@]} -gt 0 ]; then notify-send -a "Desktop doctor" "Fixed: ${fixed[*]}" "Hyprland reloaded too."
  else notify-send -a "Desktop doctor" "Everything is running" "Hyprland reloaded."; fi
elif [ ${#fixed[@]} -gt 0 ]; then
  logger -t hypr-doctor "restarted: ${fixed[*]}"
fi
