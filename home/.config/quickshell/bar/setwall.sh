#!/usr/bin/env bash
# setwall.sh <DP-1|DP-2|both> <image|video>: set live via hyprpaper (videos via livewall.sh) and save to hyprpaper.conf. Made by Claude.
target=$1; img=$2; conf="$HOME/.config/hypr/hyprpaper.conf"
mons=("$target"); [ "$target" = both ] && mons=(DP-1 DP-2)
# a video plays as a live wallpaper (livewall.sh); its first frame becomes the still picture underneath and on the lock screen
lw="$HOME/.config/hypr/scripts/livewall.sh"
case "${img,,}" in
  *.mp4|*.webm|*.mkv|*.mov)
    for m in "${mons[@]}"; do "$lw" set "$m" "$img"; done
    still="$HOME/.cache/qs-wall-thumbs/$(basename "${img%.*}")-still.jpg"
    [ "$still" -nt "$img" ] || ffmpeg -y -loglevel error -ss 1 -i "$img" -frames:v 1 -q:v 2 "$still"
    img=$still ;;
  *) for m in "${mons[@]}"; do "$lw" clear "$m"; done ;;
esac
for m in "${mons[@]}"; do
  hyprctl hyprpaper wallpaper "$m,$img,cover" >/dev/null
  python3 -I - "$conf" "$m" "$img" <<'PY'
import sys,re
p,m,img=sys.argv[1:]; t=open(p).read()
t=re.sub(r'(wallpaper \{\s*monitor = '+re.escape(m)+r'\s*path = )[^\n]*', lambda x: x.group(1)+img, t)
open(p,'w').write(t)
PY
done
# keep the lock screen background in sync (unless a lock picture was chosen on purpose)
for m in "${mons[@]}"; do
  [ "$m" = DP-1 ] && [ -e "$HOME/.config/hypr/.lock-wallpaper-fixed" ] && continue
  python3 -I - "$HOME/.config/hypr/hyprlock.conf" "$m" "$img" <<'PY'
import sys,re
p,m,img=sys.argv[1:]; t=open(p).read()
t=re.sub(r'(background \{\s*monitor = '+re.escape(m)+r'\s*path = )[^\n]*', lambda x: x.group(1)+img, t)
open(p,'w').write(t)
PY
done
