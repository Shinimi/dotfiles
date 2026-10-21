#!/usr/bin/env bash
# Idle inhibit toggle (SUPER+ALT+I, like DMS): stops auto-lock / screen-off. Made by Claude.
F="$XDG_RUNTIME_DIR/keep-awake"
if pgrep -x hypridle >/dev/null; then touch "$F"; pkill -x hypridle; notify-send "Idle inhibit" "ON – screen won't lock or turn off"
else rm -f "$F"; setsid hypridle >/dev/null 2>&1 & notify-send "Idle inhibit" "OFF – normal idle behaviour"; fi
