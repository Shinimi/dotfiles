#!/bin/sh
# ptt.sh down|up <key> – push to talk (Settings → Sound): while the chosen mouse side button is held the mic is live,
# otherwise it's muted. Works in every app and game, unlike Discord's own key on Wayland. Made by Claude.
J="$HOME/.config/hypr/settings.json"
want=$(python3 -I -c "import json;s=json.load(open('$J'));print(s.get('ptt_key','mouse:276') if s.get('ptt') else '')" 2>/dev/null)
[ -n "$want" ] && [ "$want" = "$2" ] || exit 0
case "$1" in
  down) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 ;;
  up)   wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 ;;
esac
