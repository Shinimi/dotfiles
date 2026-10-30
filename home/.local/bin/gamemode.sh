#!/usr/bin/env bash
# gamemode.sh on <window-class> [window-address] | off [auto] – runs when a game opens / the last game closes.
#  on : the game gets its own workspace (5, if on in Settings → Extras), Do not disturb, the game's
#       profile (Settings → Games): power profile, FPS cap, overlay, GPU watts; background apps get a smaller CPU/disk share
#  off: puts everything back, takes you to where you were and sums up what you missed. Made by Claude.
S="$XDG_RUNTIME_DIR/gamemode.state"; Q="$HOME/.config/quickshell/bar"; M="$HOME/.config/MangoHud"
J="$HOME/.config/hypr/settings.json"
prof() { python3 -I - "$J" "$1" <<'PY'
import json,sys,re
s=json.load(open(sys.argv[1])); cls=sys.argv[2]
m=re.match(r"steam_app_(\d+)",cls); gid=m.group(1) if m else cls
p=(s.get("game_profiles") or {}).get(gid,{})
print(int(s.get("game_mode",True)), p.get("fps",0), p.get("hud","off"), p.get("power","performance"), p.get("gpu",0))
PY
}
GW="$XDG_RUNTIME_DIR/gamews.prev"
# one run at a time: a game swapping its launcher for the real window fires "off" and "on" together,
# and the two used to overwrite each other (the overlay and FPS cap went missing)
# (everything started from here gets 9>&-: a helper that keeps running, like the session recorder or a live wallpaper,
# must not inherit the lock, or every later run waits forever)
exec 9>"$XDG_RUNTIME_DIR/gamemode.lock"; flock 9
main_ws() { hyprctl monitors -j | python3 -I -c "import json,sys;print(next(m['activeWorkspace']['id'] for m in json.load(sys.stdin) if m['name']=='DP-1'))"; }
case "$1" in
  on)
    # own workspace for games: remember where you were, move the game to 5 and follow it
    if [ -n "${3:-}" ] && ! grep -q '"game_workspace": false' "$J"; then
      cur=$(main_ws); [ "$cur" != 5 ] && [ ! -e "$GW" ] && echo "$cur" > "$GW"
      hyprctl dispatch "hl.dsp.window.move({ window = \"address:$3\", workspace = \"5\", follow = true })" >/dev/null
    fi
    if [ -e "$S" ]; then
      # already on: fine if another game is still open; if not, a game closed without "off" (crash, Steam quit): clean up first
      others=$(hyprctl clients -j | python3 -I -c "import json,sys,re;print(sum(1 for c in json.load(sys.stdin) if re.match(r'^(steam_app_\d+|cs2|gamescope)$',c['class']) and c['address']!=sys.argv[1]))" "${3:-}")
      [ "${others:-0}" -gt 0 ] && exit 0
      logger -t gamemode "stale state, resetting before ${2:-}"
      flock -u 9; "$0" off 9>&-; flock 9
    fi
    "$HOME/.local/bin/game-session.sh" start "${2:-}" "${3:-}" 9>&-   # the Games page in the control center keeps score
    read -r enabled fps hud power gpu <<<"$(prof "${2:-}")"
    [ "$enabled" = 0 ] && exit 0
    printf 'profile=%s\n' "$(powerprofilesctl get)" > "$S"
    powerprofilesctl set "$power" 2>/dev/null
    if [ "${gpu:-0}" != 0 ]; then sudo -n /usr/local/bin/gpu-ctl power "$gpu" >/dev/null 2>&1 && echo "gpu=1" >> "$S"; fi
    qs ipc -p "$Q" call bar dnd true >/dev/null 2>&1
    # background apps step back (a smaller CPU/disk share, never paused: YouTube keeps playing). Not Discord, Spotify or Steam.
    if ! grep -q '"game_bg_share": false' "$J"; then
      systemctl --user list-units --type=scope --state=running --no-legend --plain 2>/dev/null | awk '{print $1}' \
        | grep '^app-' | grep -viE 'vesktop|discord|spotify|steam' > "$XDG_RUNTIME_DIR/gamemode.bg"
      while read -r s; do systemctl --user set-property --runtime "$s" CPUWeight=25 IOWeight=25 2>/dev/null; done < "$XDG_RUNTIME_DIR/gamemode.bg"
    fi
    "$HOME/.config/hypr/scripts/screen-shader.sh" 9>&-   # colours back for the game if monochrome mode is on
    "$HOME/.config/hypr/scripts/livewall.sh" pause 9>&-   # a live wallpaper freezes: every frame goes to the game
    # MangoHud watches its config and reloads it live: the full overlay (base.conf) or the small FPS chip (fps-only.conf)
    { if [ "$hud" = fps ]; then grep -v '^no_display' "$M/fps-only.conf"; else grep -vE '^(no_display|fps_limit)' "$M/base.conf"; fi
      [ "$fps" != 0 ] && echo "fps_limit=$fps"
      [ "$hud" = off ] && echo "no_display"
    } > "$M/MangoHud.conf.new" && cat "$M/MangoHud.conf.new" > "$M/MangoHud.conf"; rm -f "$M/MangoHud.conf.new"
    logger -t gamemode "on ${2:-} power=$power fps=$fps hud=$hud gpu=${gpu:-0}" ;;
  off)
    # "off auto" (a game window closed): wait a moment, if a game window is back (launcher → game) it's not over
    if [ "${2:-}" = auto ]; then
      sleep 2
      hyprctl clients -j | grep -qE '"class": "(steam_app_[0-9]+|cs2|gamescope)"' && exit 0
    fi
    if [ -e "$GW" ]; then   # back to where you were (only if you're still on the game workspace)
      [ "$(main_ws)" = 5 ] && hyprctl dispatch "hl.dsp.focus({ workspace = \"$(cat "$GW")\" })" >/dev/null
      rm -f "$GW"
    fi
    "$HOME/.local/bin/game-session.sh" stop 9>&-
    [ -e "$S" ] || exit 0
    . "$S"; rm -f "$S"
    powerprofilesctl set "${profile:-balanced}" 2>/dev/null
    [ "${gpu:-}" = 1 ] && sudo -n /usr/local/bin/gpu-ctl power default >/dev/null 2>&1
    qs ipc -p "$Q" call bar dnd false >/dev/null 2>&1
    if [ -e "$XDG_RUNTIME_DIR/gamemode.bg" ]; then   # background apps get their normal share back
      while read -r s; do systemctl --user set-property --runtime "$s" CPUWeight= IOWeight= 2>/dev/null; done < "$XDG_RUNTIME_DIR/gamemode.bg"
      rm -f "$XDG_RUNTIME_DIR/gamemode.bg"
    fi
    "$HOME/.config/hypr/scripts/screen-shader.sh" 9>&-
    "$HOME/.config/hypr/scripts/livewall.sh" resume 9>&-
    qs ipc -p "$Q" call bar gameSummary >/dev/null 2>&1
    cp "$M/base.conf" "$M/MangoHud.conf"
    logger -t gamemode off ;;
esac
