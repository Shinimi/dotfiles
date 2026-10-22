#!/usr/bin/env bash
# Screenshots like DMS: Print = region, CTRL+Print = full screen, ALT+Print = active window.
# Saved to ~/Pictures/Screenshots and copied to the clipboard. Made by Claude.
J="$HOME/.config/hypr/settings.json"
opt() { python3 -I -c "import json;print(json.load(open('$J')).get('$1','$2'))" 2>/dev/null || echo "$2"; }
keep=$(opt shot_save True)            # Settings → Comfort: also save a file, or clipboard only
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
f="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"; [ "$keep" = True ] || f="$XDG_RUNTIME_DIR/shot.png"
case "$1" in
  region) g=$(slurp -b 11111188 -c e0e0e0ff -w 2) || exit 0; grim -g "$g" "$f" ;;
  window) g=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'); grim -g "$g" "$f" ;;
  *)      grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$f" ;;
esac
wl-copy < "$f" && "$HOME/.local/bin/kocho-sound.sh" screen-capture
if [ "$keep" = True ]; then notify-send -h boolean:suppress-sound:true -i "$f" "Screenshot saved" "$(basename "$f") — copied to clipboard"
else notify-send -h boolean:suppress-sound:true -i "$f" "Screenshot copied" "clipboard only (not saved)"; fi
