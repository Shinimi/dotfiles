#!/usr/bin/env bash
# livewall.sh – looping video wallpapers (mpvpaper), picked like any picture in the wallpaper picker (SUPER + Y).
#   livewall.sh set <DP-1|DP-2> <video>   start a video on that screen (and remember it)
#   livewall.sh clear <DP-1|DP-2>         back to a still picture on that screen
#   livewall.sh restore                   at login: start what was saved
#   livewall.sh pause | resume            game mode: frozen (no GPU/CPU use) while a game runs
# Silent, hardware-decoded, and mpv pauses by itself while windows cover it. Made by Claude.
S="$HOME/.config/hypr/livewall.conf"; touch "$S"
start() {   # $1 monitor, $2 video
  command -v mpvpaper >/dev/null || { notify-send "Live wallpaper" "mpvpaper isn't installed: sudo pacman -S mpvpaper"; exit 1; }
  pkill -f "^mpvpaper .* $1 " 2>/dev/null
  setsid -f mpvpaper -p -o "no-audio loop-file=inf hwdec=auto-safe panscan=1.0 profile=fast" "$1" "$2" >/dev/null 2>&1
}
save() { grep -v "^$1 " "$S" > "$S.tmp"; [ -n "${2:-}" ] && echo "$1 $2" >> "$S.tmp"; mv "$S.tmp" "$S"; }
case "$1" in
  set)     start "$2" "$3"; save "$2" "$3" ;;
  clear)   pkill -f "^mpvpaper .* $2 " 2>/dev/null; save "$2" ;;
  restore) while read -r m v; do [ -f "$v" ] && start "$m" "$v"; done < "$S" ;;
  pause)   pkill -STOP -x mpvpaper 2>/dev/null ;;
  resume)  pkill -CONT -x mpvpaper 2>/dev/null ;;
  *) echo "usage: livewall.sh set <mon> <video> | clear <mon> | restore | pause | resume"; exit 2 ;;
esac
