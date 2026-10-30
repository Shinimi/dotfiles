#!/usr/bin/env bash
# fetch-ascii.sh <image> [cols] [rows] – turns a picture into braille art for fastfetch, in soft greys, bright at the top and dimmer below
# (monochrome). Writes ~/.config/fastfetch/ascii.txt. Made by Claude.
src="$1"; cols="${2:-40}"; rows="${3:-23}"; out="$HOME/.config/fastfetch/ascii.txt"; t=$(mktemp -d)
[ -f "$src" ] || { echo "no image: $src"; exit 1; }
magick "$src" -auto-orient -colorspace gray -resize 400x -level 8%,92% -sigmoidal-contrast 5,45% "$t/g.png"
chafa -f symbols --symbols braille --colors none --dither diffusion --dither-grain 1x1 --dither-intensity 0.8 \
      -s "${cols}x${rows}" "$t/g.png" | sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g' |
  awk 'BEGIN{n=0}{l[n++]=$0}END{for(i=0;i<n;i++){t=i/(n>1?n-1:1); g=int(250-(250-130)*t); printf "\033[38;2;%d;%d;%dm%s\033[0m\n", g, g, g, l[i]}}' > "$out"
rm -rf "$t"; echo "$out"
