#!/usr/bin/env bash
# Drop-down terminal (SUPER + `): a kitty that slides down from the top and hides again. Made by Claude.
if hyprctl clients -j | grep -q '"class": "dropterm"'; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("term")' >/dev/null
else
  setsid -f kitty --class dropterm >/dev/null 2>&1
fi
