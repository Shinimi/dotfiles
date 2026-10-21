#!/usr/bin/env bash
# fetch-logo.sh – rounded copy of your picture with a Tokyo Night ring, used by fastfetch in kitty. Made by Claude.
src="${1:-$HOME/.face.icon}"; out="$HOME/.config/fastfetch/logo.png"; t=$(mktemp -d)
[ -f "$src" ] || exit 0
# rounded masks
magick -size 512x512 xc:black -fill white -draw "roundrectangle 0,0 511,511 112,112" "$t/outer.png"
magick -size 480x480 xc:black -fill white -draw "roundrectangle 0,0 479,479 98,98" "$t/inner.png"
# ring: diagonal blue→purple gradient cut to the outer shape
magick -size 512x512 -define gradient:angle=135 gradient:"#7aa2f7"-"#bb9af7" "$t/grad.png"
magick "$t/grad.png" "$t/outer.png" -alpha off -compose CopyOpacity -composite "$t/ring.png"
# picture cut to the inner shape
magick "$src" -resize 480x480^ -gravity center -extent 480x480 "$t/inner.png" -alpha off -compose CopyOpacity -composite "$t/pic.png"
magick "$t/ring.png" "$t/pic.png" -gravity center -compose over -composite -depth 8 "PNG32:$out"
rm -rf "$t"
