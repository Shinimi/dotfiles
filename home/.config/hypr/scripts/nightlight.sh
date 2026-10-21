#!/usr/bin/env bash
# Night light toggle (SUPER+ALT+N, like DMS). Made by Claude.
if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; notify-send "Night light" "off"
else setsid hyprsunset -t 4500 >/dev/null 2>&1 & notify-send "Night light" "on (4500K)"; fi
