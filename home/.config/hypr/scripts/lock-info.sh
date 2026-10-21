#!/usr/bin/env bash
# lock-info.sh greeting|weather|music – small text snippets for hyprlock. Made by Claude.
case "$1" in
  greeting)
    h=$(date +%H); n=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1); n=${n:-$USER}
    if   [ "$h" -lt 5 ];  then g="Good night"
    elif [ "$h" -lt 12 ]; then g="Good morning"
    elif [ "$h" -lt 18 ]; then g="Good afternoon"
    else g="Good evening"; fi
    echo "$g, ${n,,}" ;;
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
