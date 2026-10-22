#!/usr/bin/env bash
# lock-info.sh greeting|weather|music|line|island – small text snippets for hyprlock. Made by Claude.
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
  island)   # the pill at the top: workspace · time · date · weather
    w=$(grep -o -- '-\?[0-9]*°C' "$HOME/.cache/lock-weather.txt" 2>/dev/null | head -1)
    echo "󰌾   $(date +%H:%M)   ·   $(LC_TIME=C date +'%a %-d %b')${w:+   ·   $w}" ;;
  greeting)
    h=$(date +%-H); n=$(python3 -I -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/hypr/settings.json'))).get('user_name',''))" 2>/dev/null); n=${n:-$USER}
    if   [ "$h" -lt 5 ];  then g="Good night"
    elif [ "$h" -lt 12 ]; then g="Good morning"
    elif [ "$h" -lt 18 ]; then g="Good afternoon"
    else g="Good evening"; fi
    echo "$g, $n" ;;
  weather)
    c="$HOME/.cache/lock-weather.txt"
    if [ ! -s "$c" ] || [ -n "$(find "$c" -mmin +30)" ]; then
      curl -sf --max-time 6 -H "User-Agent: curl" "https://wttr.in/37.8812,41.1351?format=%c+%t+·+%C" 2>/dev/null | sed 's/+//; s/  */ /g' > "$c.tmp" && mv "$c.tmp" "$c"
    fi
    cat "$c" 2>/dev/null; echo ;;
  music)
    s=$(playerctl -p spotify status 2>/dev/null || playerctl status 2>/dev/null)
    [ "$s" = Playing ] || [ "$s" = Paused ] || exit 0
    m=$(playerctl -p spotify metadata --format '{{title}}  ·  {{artist}}' 2>/dev/null || playerctl metadata --format '{{title}}  ·  {{artist}}' 2>/dev/null)
    [ ${#m} -gt 60 ] && m="${m:0:58}…"
    [ "$s" = Playing ] && echo "󰎈  $m" || echo "󰏤  $m" ;;
esac
