#!/usr/bin/env bash
# gamemode.sh on|off – called by Hyprland when a game opens / the last game closes.
# On: Do not disturb + Performance power profile. Off: puts both back how they were. Made by Claude.
S="$XDG_RUNTIME_DIR/gamemode.state"; Q="$HOME/.config/quickshell/bar"
enabled=$(python3 -I -c "import json,os;print(json.load(open(os.path.expanduser('~/.config/hypr/settings.json'))).get('game_mode',True))" 2>/dev/null)
case "$1" in
  on)
    [ "$enabled" = False ] && exit 0
    [ -e "$S" ] && exit 0
    printf 'profile=%s\n' "$(powerprofilesctl get)" > "$S"
    powerprofilesctl set performance 2>/dev/null
    qs ipc -p "$Q" call bar dnd true >/dev/null 2>&1
    logger -t gamemode on ;;
  off)
    [ -e "$S" ] || exit 0
    . "$S"; rm -f "$S"
    powerprofilesctl set "${profile:-balanced}" 2>/dev/null
    qs ipc -p "$Q" call bar dnd false >/dev/null 2>&1
    logger -t gamemode off ;;
esac
