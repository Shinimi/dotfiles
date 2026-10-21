#!/usr/bin/env bash
# wallthumbs.sh – small cached previews of ~/Pictures/wallpaper for the settings page; prints "image<TAB>thumb". Made by Claude.
W="$HOME/Pictures/wallpaper"; T="$HOME/.cache/qs-wall-thumbs"; mkdir -p "$T"
find "$W" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\n' | sort |
  while read -r f; do t="$T/${f%.*}.jpg"; [ "$t" -nt "$W/$f" ] || printf '%s\0' "$f"; done |
  xargs -0 -r -P "$(nproc)" -I{} sh -c 'f="$1"; magick "$2/$f[0]" -auto-orient -thumbnail 400x225^ -gravity center -extent 400x225 -quality 82 "$3/${f%.*}.jpg" 2>/dev/null' _ {} "$W" "$T"
find "$W" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\n' | sort |
  while read -r f; do t="$T/${f%.*}.jpg"; [ -f "$t" ] && printf '%s\t%s\n' "$W/$f" "$t"; done
