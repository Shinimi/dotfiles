#!/usr/bin/env bash
# Idle inhibit toggle (SUPER+ALT+I, like DMS): stops auto-lock / screen-off. Made by Claude.
if pgrep -x hypridle >/dev/null; then pkill -x hypridle; notify-send "Idle inhibit" "ON – screen won't lock or turn off"
else setsid hypridle >/dev/null 2>&1 & notify-send "Idle inhibit" "OFF – normal idle behaviour"; fi
