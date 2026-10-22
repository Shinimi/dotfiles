#!/usr/bin/env bash
# Turns ~/.config/hypr/settings.json (written by the settings panel) into settings.lua and applies it live:
# Hyprland options, monitors (only when they changed), colour vibrance, night light, auto-lock time,
# and the desktop theme (icons, folder colour, cursor, font). Made by Claude.
H="$HOME/.config/hypr"; S="$HOME/.local/state/hypr-settings"; mkdir -p "$S"
python3 -I - "$H/settings.json" "$H/settings.lua" "$H/hypridle.conf" "$S" "$H/shaders" <<'PY'
import json,sys,re,os
jf,luaf,idle,state,shd=sys.argv[1:]
d={"gaps_in":4,"gaps_out":8,"border_size":2,"rounding":10,"accent":"tokyo","border_spin":True,"border_angle":45,
   "glow":False,"glow_range":14,"glow_strength":40,"shadows":True,"shadow_range":6,"shadow_tint":False,
   "dim_inactive":False,"dim_strength":12,"layout":"dwindle","smart_split":False,"snap":True,"resize_on_border":True,
   "animations":True,"anim_speed":"normal","ws_anim":"slidefade",
   "opacity_active":90,"opacity_inactive":80,"glass":60,"blur":True,"blur_size":7,"blur_passes":3,"vibrancy":18,
   "blur_brightness":85,"blur_noise":2,"blur_xray":False,"blur_popups":True,
   "sensitivity":0.4,"accel_flat":True,"natural_scroll":False,"scroll_factor":1.0,"follow_mouse":True,"middle_scroll":True,
   "middle_paste":True,"focus_on_activate":True,"repeat_rate":35,"repeat_delay":300,"kb_layout":"tr","numlock":True,
   "hide_cursor_typing":False,"cursor_hide_after":0,"ws_back_forth":False,"swallow":False,
   "night_temp":4500,"vibrance":100,"monitors":{},"lock_minutes":10,"screen_off_after":1,"mouse_wakes":False}
s=dict(d); s.update(json.load(open(jf))); b=lambda v: "true" if v else "false"
pal={"tokyo":["a28ae8","e39ec0","7fc4e3","a28ae8"],"storm":["a28ae8","7fc4e3"],"sakura":["ec6f8f","e39ec0"],
     "matcha":["8fd6b8","6fb8d6"],"sunset":["f2ad94","eec48e","ec6f8f"],"mono":["efeaf8","807a9c"]}
cols=", ".join(f'"rgba({c}ff)"' for c in pal.get(s["accent"],pal["tokyo"]))

# colour vibrance: a tiny screen shader, only used when not 100%
vib=int(s["vibrance"]); shader=""
if vib!=100:
    os.makedirs(shd,exist_ok=True); shader=os.path.join(shd,f"vibrance-{vib}.frag")
    for f in os.listdir(shd):
        if f.startswith("vibrance") and f!=os.path.basename(shader): os.remove(os.path.join(shd,f))
    open(shader,"w").write(f'''#version 300 es
// Colour vibrance for the whole screen ({vib}%). Written by apply-settings.sh. Made by Claude.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {{
    vec4 c = texture(tex, v_texcoord);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(clamp(mix(vec3(l), c.rgb, {vib/100:.2f}), 0.0, 1.0), c.a);
}}
''')

acc=pal.get(s["accent"],pal["tokyo"])
ga=f'{int(s["glow_strength"]*255/100):02x}'
glowcols=", ".join(f'"rgba({c}{ga})"' for c in acc[:2])
shadow_col=f'rgba({acc[0]}55)' if s["shadow_tint"] else "rgba(000000aa)"
# animation speed: Hyprland "speed" is a duration, so fast = smaller numbers
f={"slow":1.0,"normal":0.65,"fast":0.45}.get(s["anim_speed"],0.65)   # 1.0 = the old "normal"
ws_style={"slidefade":"slidefade 12%","slide":"slide","fade":"fade","slidevert":"slidevert"}.get(s["ws_anim"],"slidefade 12%")
an=lambda leaf,sp,bz,st=None: f'hl.animation({{ leaf = "{leaf}", enabled = true, speed = {sp*f:.2f}, bezier = "{bz}"'+(f', style = "{st}"' if st else '')+' })\n'
anims=(an("windows",4,"overshot")+an("windowsIn",3.5,"overshot","popin 80%")+an("windowsOut",2.5,"smoothOut","popin 80%")+
       an("windowsMove",4,"overshot","slide")+an("fade",3,"snappy")+an("layers",3,"snappy","fade")+
       an("workspaces",4,"easeInOut",ws_style)+an("specialWorkspace",4,"overshot","slidevert"))
main=f'''hl.config({{
    general = {{ gaps_in = {int(s["gaps_in"])}, gaps_out = {int(s["gaps_out"])}, border_size = {int(s["border_size"])},
                layout = "{s["layout"]}", resize_on_border = {b(s["resize_on_border"])}, snap = {{ enabled = {b(s["snap"])} }},
                col = {{ active_border = {{ colors = {{ {cols} }}, angle = {int(s["border_angle"])} }} }} }},
    dwindle = {{ smart_split = {b(s["smart_split"])} }},
    decoration = {{
        rounding = {int(s["rounding"])},
        active_opacity = {s["opacity_active"]/100:.2f}, inactive_opacity = {s["opacity_inactive"]/100:.2f},
        dim_inactive = {b(s["dim_inactive"])}, dim_strength = {s["dim_strength"]/100:.2f},
        blur = {{ enabled = {b(s["blur"])}, size = {int(s["blur_size"])}, passes = {int(s["blur_passes"])}, vibrancy = {s["vibrancy"]/100:.2f},
                 brightness = {s["blur_brightness"]/100:.2f}, noise = {s["blur_noise"]/100:.3f}, xray = {b(s["blur_xray"])}, popups = {b(s["blur_popups"])} }},
        shadow = {{ enabled = {b(s["shadows"])}, range = {int(s["shadow_range"])}, color = "{shadow_col}" }},
        glow = {{ enabled = {b(s["glow"])}, range = {int(s["glow_range"])}, color = {{ colors = {{ {glowcols} }}, angle = 45 }} }},
        screen_shader = "{shader}",
    }},
    animations = {{ enabled = {b(s["animations"])} }},
    input = {{ sensitivity = {float(s["sensitivity"]):.2f}, accel_profile = "{'flat' if s['accel_flat'] else 'adaptive'}",
              natural_scroll = {b(s["natural_scroll"])}, scroll_factor = {float(s["scroll_factor"]):.2f},
              follow_mouse = {1 if s["follow_mouse"] else 0}, kb_layout = "{s["kb_layout"]}", numlock_by_default = {b(s["numlock"])},
              repeat_rate = {int(s["repeat_rate"])}, repeat_delay = {int(s["repeat_delay"])},
              scroll_method = "{'on_button_down' if s.get('scroll_mode','autoscroll') == 'hold' else 'no_scroll'}" }},
    cursor = {{ hide_on_key_press = {b(s["hide_cursor_typing"])}, inactive_timeout = {int(s["cursor_hide_after"])} }},
    binds = {{ workspace_back_and_forth = {b(s["ws_back_forth"])} }},
    misc = {{ focus_on_activate = {b(s["focus_on_activate"])}, middle_click_paste = {b(s["middle_paste"])},
             enable_swallow = {b(s["swallow"])}, swallow_regex = "^(kitty)$", mouse_move_enables_dpms = {b(s["mouse_wakes"])} }},
}})
hl.animation({{ leaf = "borderangle", enabled = {b(s["border_spin"])}, speed = 60, bezier = "linear", style = "loop" }})
'''+anims
# monitors (position/scale stay as in hyprland.lua)
pos={"DP-1":("0x0",1),"DP-2":("2560x0",1)}
mon=""
for name,m in sorted((s.get("monitors") or {}).items()):
    p,sc=pos.get(name,("auto",1))
    mon+=(f'hl.monitor({{ output = "{name}", mode = "{m.get("mode","preferred")}", position = "{p}", scale = {sc}, '
          f'vrr = {int(m.get("vrr",0))}, bitdepth = {int(m.get("bitdepth",8))}, cm = "{m.get("cm","srgb")}" }})\n')
open(luaf,'w').write("-- Generated from settings.json by the settings panel. Edit there, not here.\n"+main+mon)
open(os.path.join(state,"main.lua"),'w').write(main)
open(os.path.join(state,"monitors.lua.new"),'w').write(mon)

# auto-lock time (screens go off one minute later)
t=open(idle).read(); m=int(s["lock_minutes"])
t=re.sub(r'timeout = \d+\s+# \d+ min: lock', f'timeout = {m*60}                                  # {m} min: lock', t)
t=re.sub(r'timeout = \d+\s+# \d+ min: screens off', f'timeout = {m*60+int(s["screen_off_after"])*60}                                  # {m+int(s["screen_off_after"])} min: screens off', t)
open(idle,'w').write(t)

# desktop theme (applied below only when it changed)
th={k:s.get(k,v) for k,v in {"folder_color":"blue","icon_base":"Papirus-Dark","cursor_theme":"capitaine-cursors",
    "cursor_size":24,"ui_font":"Noto Sans","ui_font_size":10}.items()}
open(os.path.join(state,"theme.json.new"),'w').write(json.dumps(th,sort_keys=True))
PY

# ---- Hyprland: apply live (a full reload makes open panels drop the next click)
code=$(tr '\n' ' ' < "$S/main.lua")
hyprctl eval "$code" 2>/dev/null | grep -qx ok || hyprctl reload >/dev/null
if ! cmp -s "$S/monitors.lua.new" "$S/monitors.lua"; then
  mv "$S/monitors.lua.new" "$S/monitors.lua"
  [ -s "$S/monitors.lua" ] && hyprctl eval "$(tr '\n' ' ' < "$S/monitors.lua")" >/dev/null
fi

# ---- night light: apply new temperature if it's on
if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; t=$(python3 -I -c "import json;print(json.load(open('$H/settings.json')).get('night_temp',4500))"); setsid hyprsunset -t "$t" >/dev/null 2>&1 & fi

# ---- auto-lock: restart hypridle so a new time applies (only if running, i.e. "keep awake" is off)
if pgrep -x hypridle >/dev/null && ! cmp -s "$H/hypridle.conf" "$S/hypridle.applied"; then pkill -x hypridle; setsid hypridle >/dev/null 2>&1 & fi
cp "$H/hypridle.conf" "$S/hypridle.applied"

# ---- desktop theme: icons, folder colour, cursor, font
if ! cmp -s "$S/theme.json.new" "$S/theme.json"; then
  mv "$S/theme.json.new" "$S/theme.json"
  eval "$(python3 -I -c "
import json,shlex; t=json.load(open('$S/theme.json'))
for k,v in t.items(): print(f'{k}={shlex.quote(str(v))}')")"
  icons="$icon_base"
  if [ "$icon_base" = Papirus-Dark ] && [ "$folder_color" != blue ]; then
    "$HOME/.local/bin/papirus-folders-color.sh" "$folder_color" >/dev/null; icons=Papirus-Shinobu
  fi
  for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$f" ] || continue
    sed -i "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$icons|; s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$cursor_theme|;
            s|^gtk-cursor-theme-size=.*|gtk-cursor-theme-size=$cursor_size|; s|^gtk-font-name=.*|gtk-font-name=$ui_font, $ui_font_size|" "$f"
  done
  gsettings set org.gnome.desktop.interface icon-theme "$icons"
  gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
  gsettings set org.gnome.desktop.interface cursor-size "$cursor_size"
  gsettings set org.gnome.desktop.interface font-name "$ui_font $ui_font_size"
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons"
  kwriteconfig6 --file kdeglobals --group General --key font "$ui_font,$ui_font_size,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  kwriteconfig6 --file kdeglobals --group General --key menuFont "$ui_font,$ui_font_size,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  kwriteconfig6 --file kdeglobals --group General --key toolBarFont "$ui_font,$((ui_font_size-1)),-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$cursor_theme"
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$cursor_size"
  printf '[Icon Theme]\nInherits=%s\n' "$cursor_theme" > "$HOME/.icons/default/index.theme"
  hyprctl setcursor "$cursor_theme" "$cursor_size" >/dev/null
  # keep Hyprland's own cursor env in step for apps started later
  sed -i "s|hl.env(\"XCURSOR_THEME\", \"[^\"]*\")|hl.env(\"XCURSOR_THEME\", \"$cursor_theme\")|; s|hl.env(\"XCURSOR_SIZE\", \"[^\"]*\")|hl.env(\"XCURSOR_SIZE\", \"$cursor_size\")|; s|hl.env(\"HYPRCURSOR_SIZE\", \"[^\"]*\")|hl.env(\"HYPRCURSOR_SIZE\", \"$cursor_size\")|" "$H/hyprland.lua"
  # tell running KDE/Qt apps (Dolphin) to pick up the new icons/fonts
  dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:4 int32:0 2>/dev/null
  dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 2>/dev/null
fi
rm -f "$S/theme.json.new" "$S/monitors.lua.new"

# ---- account, wallpapers, default apps, autostart (each only when it changed)
python3 -I - "$H/settings.json" "$S" <<'PY'
import json,sys,os
s=json.load(open(sys.argv[1])); st=sys.argv[2]
for k in ["avatar","user_name","wall_main","wall_side","default_apps","autostart"]:
    v=json.dumps(s.get(k),sort_keys=True); f=os.path.join(st,k+".applied")
    old=open(f).read() if os.path.exists(f) else None
    if v!=old and s.get(k) not in (None,"",[],{}): open(os.path.join(st,k+".todo"),'w').write(json.dumps(s.get(k)))
    open(f,'w').write(v)
PY
todo() { [ -f "$S/$1.todo" ] && python3 -I -c "import json,sys;v=json.load(open(sys.argv[1]));print(v if isinstance(v,str) else json.dumps(v))" "$S/$1.todo" && rm -f "$S/$1.todo"; }
U=$(busctl --system call org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts FindUserByName s "$USER" 2>/dev/null | cut -d'"' -f2)
if a=$(todo avatar) && [ -f "$a" ]; then
  magick "$a" -auto-orient -resize 512x512^ -gravity center -extent 512x512 "PNG:$HOME/.face.icon" 2>/dev/null && cp "$HOME/.face.icon" "$HOME/.face"
  [ -n "$U" ] && busctl --system call org.freedesktop.Accounts "$U" org.freedesktop.Accounts.User SetIconFile s "$HOME/.face.icon" >/dev/null 2>&1
fi
if n=$(todo user_name) && [ -n "$n" ] && [ -n "$U" ]; then busctl --system call org.freedesktop.Accounts "$U" org.freedesktop.Accounts.User SetRealName s "$n" >/dev/null 2>&1; fi
w=$(todo wall_main) && [ -f "$w" ] && "$HOME/.config/quickshell/bar/setwall.sh" DP-1 "$w"
w=$(todo wall_side) && [ -f "$w" ] && "$HOME/.config/quickshell/bar/setwall.sh" DP-2 "$w"
if d=$(todo default_apps); then
  python3 -I -c "import json,sys;[print(k,v) for k,v in json.loads(sys.argv[1]).items()]" "$d" | while read -r cat app; do
    python3 -I "$HOME/.config/quickshell/bar/sysinfo.py" setdefault "$cat" "$app" >/dev/null; done
fi
# apps that open at login (run by Hyprland at start-up)
python3 -I - "$H/settings.json" "$H/autostart.sh" <<'PY'
import json,sys,shlex
apps=json.load(open(sys.argv[1])).get("autostart",[]) or []
open(sys.argv[2],'w').write("#!/usr/bin/env bash\n# Apps that open at login – chosen in Settings → Autostart. Generated, edit there. Made by Claude.\nsleep 3\n"+
    "".join(f"gtk-launch {shlex.quote(a)} >/dev/null 2>&1 &\n" for a in apps))
PY
chmod +x "$H/autostart.sh"; rm -f "$S"/*.todo

# ---- fastfetch art (text art from a picture, your picture, or the distro logo)
python3 -I - "$H/settings.json" "$S" <<'PY'
import json,sys,os,subprocess,re
s=json.load(open(sys.argv[1])); st=sys.argv[2]
mode=s.get("fetch_logo","ascii"); src=s.get("fetch_source","") or os.path.expanduser("~/.config/fastfetch/shinobu-source.png")
key=json.dumps([mode,src]); f=os.path.join(st,"fetch.applied")
if os.path.exists(f) and open(f).read()==key: sys.exit()
if mode=="ascii": subprocess.run([os.path.expanduser("~/.local/bin/fetch-ascii.sh"),src],capture_output=True)
if mode in ("portrait","picture"):
    pic=os.path.expanduser("~/.config/fastfetch/shinobu-portrait.png") if mode=="portrait" else os.path.expanduser("~/.face.icon")
    subprocess.run([os.path.expanduser("~/.local/bin/fetch-logo.sh"),pic],capture_output=True)
logo={"kamon":'{ "type": "file-raw", "source": "~/.config/fastfetch/kamon.txt", "padding": { "top": 1, "left": 3, "right": 6 } }',
      "butterfly":'{ "type": "file-raw", "source": "~/.config/fastfetch/butterfly.txt", "padding": { "top": 2, "left": 3, "right": 5 } }',
      "portrait":'{ "type": "kitty-direct", "source": "~/.config/fastfetch/logo.png", "width": 30, "height": 14, "padding": { "top": 1, "left": 3, "right": 4 } }',
      "ascii":'{ "type": "file-raw", "source": "~/.config/fastfetch/ascii.txt", "padding": { "top": 1, "left": 2, "right": 4 } }',
      "picture":'{ "type": "kitty-direct", "source": "~/.config/fastfetch/logo.png", "width": 34, "height": 15, "padding": { "top": 1, "left": 3, "right": 5 } }',
      "distro":'{ "type": "builtin", "color": { "1": "#a28ae8", "2": "#e39ec0" }, "padding": { "top": 1, "left": 2, "right": 4 } }'}[mode]
p=os.path.expanduser("~/.config/fastfetch/config.jsonc"); c=open(p).read()
c=re.sub(r'  "logo": .*// LOGO \(Settings → Theme\)', lambda m: f'  "logo": {logo}, // LOGO (Settings → Theme)', c)
open(p,'w').write(c); open(f,'w').write(key)
PY
