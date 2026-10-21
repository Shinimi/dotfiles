#!/usr/bin/env bash
# GPU usage + temperature for Waybar (AMD). Made by Claude.
for d in /sys/class/drm/card*/device; do
  [ "$(cat "$d/vendor" 2>/dev/null)" = 0x1002 ] || continue
  u=$(cat "$d/gpu_busy_percent"); t=$(( $(cat "$d"/hwmon/hwmon*/temp2_input) / 1000 ))
  printf '{"text":"\U000f08ae  %s%%  %s°","tooltip":"GPU %s%% · hotspot %s°C"}\n' "$u" "$t" "$u" "$t"; exit
done
