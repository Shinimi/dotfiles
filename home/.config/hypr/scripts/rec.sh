#!/usr/bin/env bash
# rec.sh – screen recording on/off (SUPER + ALT + R, or the red dot in the bar to stop). Records the main screen at
# 60 fps on the graphics card (barely costs FPS) with the desktop sound, into ~/Videos/Recordings. Made by Claude.
Q="$HOME/.config/quickshell/bar"
if pid=$(pgrep -f "^gpu-screen-recorder "); then   # (-x cannot match: the name is longer than 15 characters)
  kill -INT $pid                       # stop: the file is finished and saved
  exit 0
fi
dir="$HOME/Videos/Recordings"; mkdir -p "$dir"
f="$dir/Recording $(date '+%Y-%m-%d %H.%M.%S').mp4"
(
  qs ipc -p "$Q" call bar recording true >/dev/null 2>&1
  gpu-screen-recorder -w DP-1 -f 60 -a default_output -ac aac -o "$f" >/dev/null 2>&1
  qs ipc -p "$Q" call bar recording false >/dev/null 2>&1
  if [ -s "$f" ]; then
    len=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null | cut -d. -f1)
    notify-send -a Recording -i media-record "Recording saved" "$(basename "$f")  ·  ${len:-?} s  ·  in Videos/Recordings"
  fi
) &
disown
