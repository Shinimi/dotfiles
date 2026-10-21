#!/usr/bin/env bash
# Screenshots like DMS: Print = region, CTRL+Print = full screen, ALT+Print = active window.
# Saved to ~/Pictures/Screenshots and copied to the clipboard. Made by Claude.
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
f="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
case "$1" in
  region) g=$(slurp -b 1a1b2688 -c 7aa2f7ff -w 2) || exit 0; grim -g "$g" "$f" ;;
  window) g=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'); grim -g "$g" "$f" ;;
  *)      grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$f" ;;
esac
wl-copy < "$f" && notify-send -i "$f" "Screenshot saved" "$(basename "$f") — copied to clipboard"
