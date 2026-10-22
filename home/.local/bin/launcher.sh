#!/usr/bin/env bash
# launcher.sh [drun|run|window] – rofi with a click-outside-to-close shield. Made by Claude.
pkill -x rofi && exit 0                       # pressing the key again closes it
Q="$HOME/.config/quickshell/bar"
qs ipc -p "$Q" call shield enable >/dev/null 2>&1
rofi -show "${1:-drun}"
qs ipc -p "$Q" call shield disable >/dev/null 2>&1
