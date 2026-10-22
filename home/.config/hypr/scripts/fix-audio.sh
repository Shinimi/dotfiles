#!/usr/bin/env bash
# fix-audio.sh – when sound is stuck: restarts the audio server, puts your EQ / clean mic back, and
# restarts Spotify and Discord (they don't reconnect by themselves), resuming the music. Made by Claude.
notify-send -h boolean:suppress-sound:true -a Audio "Fixing audio…" "restarting the sound server"
playing=$(playerctl -p spotify status 2>/dev/null)
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2; "$HOME/.local/bin/audio-fx.sh" restore
for app in spotify vesktop; do
  pgrep -x "$app" >/dev/null || continue
  pkill -TERM -x "$app"; for i in $(seq 1 20); do pgrep -x "$app" >/dev/null || break; sleep 0.25; done
  case "$app" in spotify) setsid -f spotify-launcher >/dev/null 2>&1 ;; vesktop) setsid -f /usr/bin/vesktop >/dev/null 2>&1 ;; esac
done
if [ "$playing" = Playing ]; then for i in $(seq 1 30); do sleep 0.5; playerctl -p spotify play 2>/dev/null && break; done; fi
notify-send -a Audio "Audio fixed" "sound server restarted · browsers may need a tab reload"
