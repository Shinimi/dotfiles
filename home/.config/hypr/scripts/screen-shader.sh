#!/usr/bin/env bash
# screen-shader.sh – puts the right whole-screen shader on, live: monochrome (if on and no game is running),
# else the colour vibrance one (if not 100%), else none. Called by gamemode.sh. Made by Claude.
H="$HOME/.config/hypr"
sh=$(python3 -I - "$H/settings.json" "$H/shaders" "$XDG_RUNTIME_DIR/gamemode.state" <<'PY'
import json,os,sys
s=json.load(open(sys.argv[1])); d=sys.argv[2]; vib=int(s.get("vibrance",100))
if s.get("mono_mode") and not os.path.exists(sys.argv[3]): print(os.path.join(d,"mono.frag"))
elif vib!=100: print(os.path.join(d,f"vibrance-{vib}.frag"))
else: print("")
PY
)
hyprctl eval "hl.config({ decoration = { screen_shader = \"$sh\" } })" >/dev/null
