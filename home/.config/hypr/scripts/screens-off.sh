#!/usr/bin/env bash
# screens-off.sh – hypridle's "screens off" step. At night (22:00–08:00, with the desk clock on) only the main screen
# switches off, so the side screen can stay a bedside clock; otherwise both go off. Made by Claude.
h=$(date +%-H)
if { [ "$h" -ge 22 ] || [ "$h" -lt 8 ]; } && ! grep -q '"desk_clock": false' "$HOME/.config/hypr/settings.json" 2>/dev/null; then
  hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "DP-1" })' >/dev/null
else
  hyprctl dispatch 'hl.dsp.dpms({ action = "off" })' >/dev/null
fi
