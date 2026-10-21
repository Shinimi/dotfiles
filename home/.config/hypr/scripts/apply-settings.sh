#!/usr/bin/env bash
# Turns ~/.config/hypr/settings.json (written by the settings panel) into settings.lua, reloads, and
# applies the non-Hyprland bits (night light, auto-lock time). Made by Claude.
H="$HOME/.config/hypr"
python3 -I - "$H/settings.json" "$H/settings.lua" "$H/hypridle.conf" <<'PY'
import json,sys,re
d={"gaps_in":4,"gaps_out":8,"border_size":2,"rounding":10,"opacity_active":90,"opacity_inactive":80,"blur":True,
   "blur_size":7,"blur_passes":3,"shadows":True,"animations":True,"sensitivity":0.4,"follow_mouse":True,
   "middle_scroll":True,"focus_on_activate":True,"night_temp":4500,"glass":60,"accent":"tokyo","border_spin":True,
   "dim_inactive":False,"repeat_rate":35,"repeat_delay":300,"lock_minutes":10,"vibrancy":18}
s=dict(d); s.update(json.load(open(sys.argv[1]))); b=lambda v: "true" if v else "false"
pal={"tokyo":["7aa2f7","bb9af7","7dcfff","7aa2f7"],"storm":["7aa2f7","7dcfff"],"sakura":["f7768e","bb9af7"],
     "matcha":["9ece6a","73daca"],"sunset":["ff9e64","e0af68","f7768e"],"mono":["c0caf5","565f89"]}
cols=", ".join(f'"rgba({c}ff)"' for c in pal.get(s["accent"],pal["tokyo"]))
lua=f'''-- Generated from settings.json by the settings panel. Edit there, not here.
hl.config({{
    general = {{ gaps_in = {int(s["gaps_in"])}, gaps_out = {int(s["gaps_out"])}, border_size = {int(s["border_size"])},
                col = {{ active_border = {{ colors = {{ {cols} }}, angle = 45 }} }} }},
    decoration = {{
        rounding = {int(s["rounding"])},
        active_opacity = {s["opacity_active"]/100:.2f}, inactive_opacity = {s["opacity_inactive"]/100:.2f},
        dim_inactive = {b(s["dim_inactive"])}, dim_strength = 0.12,
        blur = {{ enabled = {b(s["blur"])}, size = {int(s["blur_size"])}, passes = {int(s["blur_passes"])}, vibrancy = {s["vibrancy"]/100:.2f} }},
        shadow = {{ enabled = {b(s["shadows"])} }},
    }},
    animations = {{ enabled = {b(s["animations"])} }},
    input = {{ sensitivity = {float(s["sensitivity"]):.2f}, follow_mouse = {1 if s["follow_mouse"] else 0},
              repeat_rate = {int(s["repeat_rate"])}, repeat_delay = {int(s["repeat_delay"])},
              scroll_method = "{'on_button_down' if s['middle_scroll'] else '2fg'}" }},
    misc = {{ focus_on_activate = {b(s["focus_on_activate"])} }},
}})
hl.animation({{ leaf = "borderangle", enabled = {b(s["border_spin"])}, speed = 60, bezier = "linear", style = "loop" }})
'''
open(sys.argv[2],'w').write(lua)
# auto-lock time (screens go off one minute later)
p=sys.argv[3]; t=open(p).read(); m=int(s["lock_minutes"])
t=re.sub(r'timeout = \d+(\s+# \d+ min: lock)', lambda x: f'timeout = {m*60}  # {m} min: lock', t)
t=re.sub(r'timeout = \d+(\s+# \d+ min: screens off)', lambda x: f'timeout = {m*60+60}  # {m+1} min: screens off', t)
t=re.sub(r'(timeout = \d+)\s+# (\d+ min: lock)', r'\1                                  # \2', t)
open(p,'w').write(t)
print(m)
PY
# apply live (a full reload makes open panels drop the next click); fall back to reload if eval fails
code=$(grep -v '^--' "$H/settings.lua" | tr '\n' ' ')
hyprctl eval "$code" 2>/dev/null | grep -qx ok || hyprctl reload >/dev/null
# night light: apply new temperature if it's on
if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; t=$(python3 -I -c "import json;print(json.load(open('$H/settings.json')).get('night_temp',4500))"); setsid hyprsunset -t "$t" >/dev/null 2>&1 & fi
# auto-lock: restart hypridle so a new time applies (only if it's running, i.e. "keep awake" is off)
if pgrep -x hypridle >/dev/null && ! cmp -s "$H/hypridle.conf" "$H/.hypridle.applied"; then pkill -x hypridle; setsid hypridle >/dev/null 2>&1 & fi
cp "$H/hypridle.conf" "$H/.hypridle.applied"
