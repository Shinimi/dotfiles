#!/usr/bin/env bash
# Night light toggle (SUPER+ALT+N, like DMS). Made by Claude.
if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; notify-send "Night light" "off"
else t=$(python3 -I -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/hypr/settings.json'))).get('night_temp',4500))"); setsid hyprsunset -t "$t" >/dev/null 2>&1 & notify-send "Night light" "on (${t}K)"; fi
