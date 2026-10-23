#!/usr/bin/env bash
# dropapp.sh <name> <class-regex> <launch command…>  (SUPER + M = Spotify, SUPER + C = Discord)
# Pulls the app off the side screen into a big floating window over whatever you're doing; the same key sends it
# back to the side screen. Not running yet? It starts it first. Made by Claude.
name=$1; re=$2; shift 2
S="$XDG_RUNTIME_DIR/dropapp-$name"
find_win() { hyprctl clients -j | python3 -I -c "
import json,re,sys
for c in json.load(sys.stdin):
    if re.fullmatch(sys.argv[1], c['class'] or '', re.I): print(c['address'], c['workspace']['name']); break" "$re"; }
d() { hyprctl dispatch "$1" >/dev/null; }

read -r addr ws <<<"$(find_win)"
if [ -z "$addr" ]; then                       # start it, then wait for its window
  setsid -f "$@" >/dev/null 2>&1
  for _ in $(seq 1 60); do sleep 0.25; read -r addr ws <<<"$(find_win)"; [ -n "$addr" ] && break; done
  [ -z "$addr" ] && exit 0
  sleep 0.5
fi
read -r curws mw mh <<<"$(hyprctl monitors -j | python3 -I -c "import json,sys;m=next(m for m in json.load(sys.stdin) if m['name']=='DP-1');print(m['activeWorkspace']['name'],m['width'],m['height'])")"
w="address:$addr"

if [ -e "$S" ] && [ "$(cat "$S")" = "$addr" ] && [ "$ws" = "$curws" ]; then
  # it's down here with you: send it back to the side screen
  d "hl.dsp.window.float({ action = \"disable\", window = \"$w\" })"
  d "hl.dsp.window.move({ window = \"$w\", workspace = \"name:side\", follow = false })"
  rm -f "$S"
else
  d "hl.dsp.window.move({ window = \"$w\", workspace = \"$curws\", follow = false })"
  d "hl.dsp.window.float({ action = \"enable\", window = \"$w\" })"
  d "hl.dsp.window.resize({ x = $((mw * 60 / 100)), y = $((mh * 72 / 100)), relative = false, window = \"$w\" })"
  d "hl.dsp.window.center({ window = \"$w\" })"
  d "hl.dsp.focus({ window = \"$w\" })"
  echo "$addr" > "$S"
fi
