#!/usr/bin/env bash
# kocho-sound.sh <event> – plays your voice clip for the event if you added one
# (~/.local/share/sounds/kocho-voice/<event>[-N].ogg|mp3|wav|…), otherwise the Kochō koto sound.
# Quiet during game mode or when Sounds is off in Settings. Made by Claude.
[ -e "$XDG_RUNTIME_DIR/gamemode.state" ] && exit 0
grep -q '"sounds": false' "$HOME/.config/hypr/settings.json" 2>/dev/null && exit 0
V="$HOME/.local/share/sounds/kocho-voice"
mapfile -t clips < <(find "$V" -maxdepth 1 -type f \( -name "$1.*" -o -name "$1-*.*" \) ! -name "*.txt" 2>/dev/null)
if [ ${#clips[@]} -gt 0 ]; then
  f="${clips[RANDOM % ${#clips[@]}]}"
else
  f="$HOME/.local/share/sounds/mono/stereo/$1.oga"; [ -f "$f" ] || exit 0
fi
pw-play --volume 0.75 "$f" >/dev/null 2>&1 &
