#!/usr/bin/env bash
# vol.sh up|down – volume keys; the step comes from Settings → Comfort (volume_step, default 3%). Made by Claude.
st=$(python3 -I -c "import json;print(json.load(open('$HOME/.config/hypr/settings.json')).get('volume_step',3))" 2>/dev/null); st=${st:-3}
case "$1" in
  up)   wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "${st}%+" ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${st}%-" ;;
esac
"$HOME/.local/bin/kocho-sound.sh" audio-volume-change
