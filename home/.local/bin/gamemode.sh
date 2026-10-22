#!/usr/bin/env bash
# gamemode.sh on <window-class> | off – runs when a game opens / the last game closes.
#  on : Do not disturb, the game's profile (Settings → Games): power profile, FPS cap, overlay
#  off: puts everything back. Made by Claude.
S="$XDG_RUNTIME_DIR/gamemode.state"; Q="$HOME/.config/quickshell/bar"; M="$HOME/.config/MangoHud"
J="$HOME/.config/hypr/settings.json"
prof() { python3 -I - "$J" "$1" <<'PY'
import json,sys,re
s=json.load(open(sys.argv[1])); cls=sys.argv[2]
m=re.match(r"steam_app_(\d+)",cls); gid=m.group(1) if m else cls
p=(s.get("game_profiles") or {}).get(gid,{})
print(int(s.get("game_mode",True)), p.get("fps",0), p.get("hud","off"), p.get("power","performance"))
PY
}
case "$1" in
  on)
    [ -e "$S" ] && exit 0
    read -r enabled fps hud power <<<"$(prof "${2:-}")"
    [ "$enabled" = 0 ] && exit 0
    printf 'profile=%s\n' "$(powerprofilesctl get)" > "$S"
    powerprofilesctl set "$power" 2>/dev/null
    qs ipc -p "$Q" call bar dnd true >/dev/null 2>&1
    # MangoHud watches its config and reloads it live
    { grep -vE '^(no_display|fps_limit|preset)' "$M/base.conf"
      [ "$fps" != 0 ] && echo "fps_limit=$fps"
      case "$hud" in off) echo "no_display" ;; fps) printf 'preset=1\n' ;; full) : ;; esac
    } > "$M/MangoHud.conf"
    logger -t gamemode "on ${2:-} power=$power fps=$fps hud=$hud" ;;
  off)
    [ -e "$S" ] || exit 0
    . "$S"; rm -f "$S"
    powerprofilesctl set "${profile:-balanced}" 2>/dev/null
    qs ipc -p "$Q" call bar dnd false >/dev/null 2>&1
    cp "$M/base.conf" "$M/MangoHud.conf"
    logger -t gamemode off ;;
esac
