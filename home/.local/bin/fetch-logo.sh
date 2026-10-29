#!/usr/bin/env bash
# fetch-logo.sh – rounded copy of your picture with a monochrome ring, used by fastfetch in kitty. Made by Claude.
src="${1:-$HOME/.face.icon}"; out="$HOME/.config/fastfetch/logo.png"; t=$(mktemp -d)
[ -f "$src" ] || exit 0
# rounded masks
magick -size 512x512 xc:black -fill white -draw "roundrectangle 0,0 511,511 120,120" "$t/outer.png"
magick -size 496x496 xc:black -fill white -draw "roundrectangle 0,0 495,495 112,112" "$t/inner.png"
# ring: diagonal blue→purple gradient cut to the outer shape
magick -size 512x512 -define gradient:angle=135 gradient:"#e0e0e0"-"#b0b0b0" "$t/grad.png"
magick "$t/grad.png" "$t/outer.png" -alpha off -compose CopyOpacity -composite "$t/ring.png"
# picture cut to the inner shape
magick "$src" -resize 496x496^ -gravity center -extent 496x496 "$t/inner.png" -alpha off -compose CopyOpacity -composite "$t/pic.png"
magick "$t/ring.png" "$t/pic.png" -gravity center -compose over -composite -depth 8 "PNG32:$out"
rm -rf "$t"
