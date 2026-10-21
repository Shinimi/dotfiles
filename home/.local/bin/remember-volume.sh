#!/usr/bin/env bash
# Remembers the default output volume across logins / audio restarts (the Fuxi headset
# runs without ALSA profiles, so WirePlumber can't restore it). Made by Claude.
state="$HOME/.local/state/last-volume"
guard=0
get() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}'; }
restore() { sleep 2; [ -s "$state" ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ "$(cat "$state")"; guard=$(( $(date +%s) + 4 )); }
for i in $(seq 1 30); do [ -n "$(get)" ] && break; sleep 1; done
restore
pactl subscribe 2>/dev/null | grep --line-buffered -E "'(new|change)' on sink" | while read -r line; do
  if [[ "$line" == *"'new'"* ]]; then restore; continue; fi          # sink (re)appeared: restore
  [ "$(date +%s)" -lt "$guard" ] && continue                          # ignore resets right after
  v=$(get); [ -n "$v" ] && [ "$v" != "$(cat "$state" 2>/dev/null)" ] && echo "$v" > "$state"
done
