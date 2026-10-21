#!/usr/bin/env bash
# setwall.sh <DP-1|DP-2|both> <image>: set live via hyprpaper and save to hyprpaper.conf. Made by Claude.
target=$1; img=$2; conf="$HOME/.config/hypr/hyprpaper.conf"
mons=("$target"); [ "$target" = both ] && mons=(DP-1 DP-2)
for m in "${mons[@]}"; do
  hyprctl hyprpaper wallpaper "$m,$img,cover" >/dev/null
  python3 -I - "$conf" "$m" "$img" <<'PY'
import sys,re
p,m,img=sys.argv[1:]; t=open(p).read()
t=re.sub(r'(wallpaper \{\s*monitor = '+re.escape(m)+r'\s*path = )[^\n]*', lambda x: x.group(1)+img, t)
open(p,'w').write(t)
PY
done
# keep the lock screen background in sync
for m in "${mons[@]}"; do
  python3 -I - "$HOME/.config/hypr/hyprlock.conf" "$m" "$img" <<'PY'
import sys,re
p,m,img=sys.argv[1:]; t=open(p).read()
t=re.sub(r'(background \{\s*monitor = '+re.escape(m)+r'\s*path = )[^\n]*', lambda x: x.group(1)+img, t)
open(p,'w').write(t)
PY
done
