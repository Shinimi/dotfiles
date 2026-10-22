#!/usr/bin/env bash
# Focus mode (SUPER + Z): no gaps, no bar, no pop-ups, no sounds — just the window. Again to leave. Made by Claude.
F="$XDG_RUNTIME_DIR/focus-mode"; QS="qs ipc -p $HOME/.config/quickshell/bar call"
if [ -e "$F" ]; then
  rm -f "$F"
  hyprctl eval "$(tr '\n' ' ' < "$HOME/.local/state/hypr-settings/main.lua")" >/dev/null   # your normal gaps/rounding
  $QS bar focus false; $QS bar dnd false
else
  : > "$F"
  hyprctl eval 'hl.config({ general = { gaps_in = 0, gaps_out = 0 }, decoration = { rounding = 0 } })' >/dev/null
  $QS bar focus true; $QS bar dnd true
fi
