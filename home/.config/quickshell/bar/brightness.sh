#!/usr/bin/env bash
# brightness.sh get | set <DP-1|DP-2> <0-100> – monitor brightness over DDC/CI. Made by Claude.
M="$XDG_RUNTIME_DIR/ddc-buses"
if [ ! -s "$M" ]; then ddcutil detect --brief 2>/dev/null | awk '/I2C bus/{b=$3; sub("/dev/i2c-","",b)} /DRM connector/{c=$3; sub("card[0-9]+-","",c); print c, b}' > "$M"; fi
case "$1" in
  get) printf '{'; first=1; while read -r c b; do v=$(ddcutil -b "$b" getvcp 10 --brief 2>/dev/null | awk '{print $4}'); [ $first = 0 ] && printf ','; printf '"%s":%s' "$c" "${v:-100}"; first=0; done < "$M"; echo '}' ;;
  set) b=$(awk -v c="$2" '$1==c{print $2}' "$M"); [ -n "$b" ] && ddcutil -b "$b" --noverify setvcp 10 "$3" >/dev/null 2>&1 ;;
esac
