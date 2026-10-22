#!/usr/bin/env bash
# zoom.sh in|out|reset — screen magnifier that follows the mouse (SUPER + ALT + scroll). Made by Claude.
z=$(hyprctl getoption cursor:zoom_factor -j | python3 -I -c "import json,sys;print(json.load(sys.stdin)['float'])")
case "$1" in
  in)    z=$(python3 -I -c "print(min(6.0, $z * 1.25))") ;;
  out)   z=$(python3 -I -c "print(max(1.0, $z / 1.25))") ;;
  *)     z=1.0 ;;
esac
hyprctl eval "hl.config({ cursor = { zoom_factor = $z } })" >/dev/null
