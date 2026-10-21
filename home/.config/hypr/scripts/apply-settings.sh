#!/usr/bin/env bash
# Turns ~/.config/hypr/settings.json (written by the Hyprland settings panel) into settings.lua and reloads. Made by Claude.
H="$HOME/.config/hypr"
python3 -I - "$H/settings.json" "$H/settings.lua" <<'PY'
import json,sys
s=json.load(open(sys.argv[1])); b=lambda v: "true" if v else "false"
lua=f'''-- Generated from settings.json by the Hyprland settings panel. Edit there, not here.
hl.config({{
    general = {{ gaps_in = {int(s["gaps_in"])}, gaps_out = {int(s["gaps_out"])}, border_size = {int(s["border_size"])} }},
    decoration = {{
        rounding = {int(s["rounding"])},
        active_opacity = {s["opacity_active"]/100:.2f}, inactive_opacity = {s["opacity_inactive"]/100:.2f},
        blur = {{ enabled = {b(s["blur"])}, size = {int(s["blur_size"])}, passes = {int(s["blur_passes"])} }},
        shadow = {{ enabled = {b(s["shadows"])} }},
    }},
    animations = {{ enabled = {b(s["animations"])} }},
    input = {{ sensitivity = {float(s["sensitivity"]):.2f}, follow_mouse = {1 if s["follow_mouse"] else 0},
              scroll_method = "{'on_button_down' if s['middle_scroll'] else '2fg'}" }},
    misc = {{ focus_on_activate = {b(s["focus_on_activate"])} }},
}})
'''
open(sys.argv[2],'w').write(lua)
PY
hyprctl reload >/dev/null
# night light: apply new temperature if it's on
if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; t=$(python3 -I -c "import json;print(json.load(open('$H/settings.json'))['night_temp'])"); setsid hyprsunset -t "$t" >/dev/null 2>&1 & fi
