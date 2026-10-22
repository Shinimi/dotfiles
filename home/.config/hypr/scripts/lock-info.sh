#!/usr/bin/env bash
# lock-info.sh greeting|music|line|island – small text snippets for hyprlock. Made by Claude.
case "$1" in
  line)   # today's line, the same one the desktop shows (read from Journey.qml)
    python3 -I - <<'PY'
import re,datetime,os
t=open(os.path.expanduser("~/.config/quickshell/bar/Journey.qml")).read()
lines=re.findall(r'^\s*"([^"]+)",?\s*$', t, re.M)
d=datetime.date.today(); n=(d-datetime.date(d.year,1,1)).days+1
print("— " + lines[n % len(lines)] if lines else "")
PY
    ;;
  island)   # the pill at the top: time · date
    echo "󰌾   $(date +%H:%M)   ·   $(LC_TIME=C date +'%a %-d %b')" ;;
  greeting)
    h=$(date +%-H); n=$(python3 -I -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/hypr/settings.json'))).get('user_name',''))" 2>/dev/null); n=${n:-$USER}
    if   [ "$h" -lt 5 ];  then g="Good night"
    elif [ "$h" -lt 12 ]; then g="Good morning"
    elif [ "$h" -lt 18 ]; then g="Good afternoon"
    else g="Good evening"; fi
    echo "$g, $n" ;;
  music)
    s=$(playerctl -p spotify status 2>/dev/null || playerctl status 2>/dev/null)
    [ "$s" = Playing ] || [ "$s" = Paused ] || exit 0
    m=$(playerctl -p spotify metadata --format '{{title}}  ·  {{artist}}' 2>/dev/null || playerctl metadata --format '{{title}}  ·  {{artist}}' 2>/dev/null)
    [ ${#m} -gt 60 ] && m="${m:0:58}…"
    [ "$s" = Playing ] && echo "󰎈  $m" || echo "󰏤  $m" ;;
esac
