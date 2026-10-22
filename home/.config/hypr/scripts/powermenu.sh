#!/usr/bin/env bash
# Power menu (SUPER+X / bar button). Big icon row, Tokyo Night. Made by Claude.
pgrep -x rofi >/dev/null && { pkill -x rofi; exit 0; }
lock=$''; logout=$''; sleep=$''; reboot=$''; off=$''
choice=$(printf '%s\n%s\n%s\n%s\n%s\n' "$lock" "$logout" "$sleep" "$reboot" "$off" | rofi -dmenu -p "" -selected-row 0 -theme-str '
  window { width: 620px; border: 2px; border-color: #cf6b6b; border-radius: 16px; padding: 18px; }
  mainbox { children: [ "message", "listview" ]; spacing: 14px; }
  message { background-color: transparent; padding: 0; }
  textbox { horizontal-align: 0.5; text-color: #c8c8c8; font: "JetBrainsMono Nerd Font Bold 12"; }
  listview { columns: 5; lines: 1; spacing: 12px; fixed-height: true; }
  element { orientation: vertical; padding: 24px 0; border-radius: 12px; background-color: #1c1c1c; }
  element-text { font: "JetBrainsMono Nerd Font 30"; horizontal-align: 0.5; vertical-align: 0.5; }
  element normal.normal, element alternate.normal { background-color: #1c1c1c; text-color: #eaeaea; }
  element selected.normal { background-color: #cf6b6b; text-color: #111111; }' \
  -mesg "Lock · Logout · Suspend · Reboot · Shutdown")
case "$choice" in
  "$lock")   loginctl lock-session ;;
  "$logout") hyprctl dispatch 'hl.dsp.exit()' ;;
  "$sleep")  systemctl suspend ;;
  "$reboot") systemctl reboot ;;
  "$off")    systemctl poweroff ;;
esac
