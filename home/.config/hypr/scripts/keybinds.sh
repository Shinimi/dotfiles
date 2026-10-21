#!/usr/bin/env bash
# Shows the keybind list from the top of hyprland.lua (SUPER+F1). Made by Claude.
sed -n '/KEYBINDS/,/^-- =====/p' "$HOME/.config/hypr/hyprland.lua" | sed '1d;$d; s/^--  *//' | grep -v '^$' |
  rofi -dmenu -i -p keybinds -theme-str 'window {width: 760px;} listview {lines: 22;}' >/dev/null
