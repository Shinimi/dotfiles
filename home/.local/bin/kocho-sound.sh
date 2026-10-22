#!/usr/bin/env bash
# kocho-sound.sh <event> – plays a Kochō chime (quiet during Do not disturb / game mode). Made by Claude.
[ -e "$XDG_RUNTIME_DIR/gamemode.state" ] && exit 0
grep -q '"sounds": false' "$HOME/.config/hypr/settings.json" 2>/dev/null && exit 0
f="$HOME/.local/share/sounds/kocho/stereo/$1.oga"; [ -f "$f" ] || exit 0
pw-play --volume 0.7 "$f" >/dev/null 2>&1 &
