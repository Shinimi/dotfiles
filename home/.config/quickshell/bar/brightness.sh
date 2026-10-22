#!/usr/bin/env bash
# brightness.sh get | set <DP-1|DP-2> <0-100> – monitor brightness over DDC/CI. Made by Claude.
# Asking the monitors is slow (~1 s, and one bus sometimes times out), so "get" answers from a small cache
# straight away and only re-reads the monitors in the background when the cache is over 10 minutes old.
M="$XDG_RUNTIME_DIR/ddc-buses"; C="$XDG_RUNTIME_DIR/ddc-bright.json"
if [ ! -s "$M" ]; then ddcutil detect --brief 2>/dev/null | awk '/I2C bus/{b=$3; sub("/dev/i2c-","",b)} /DRM connector/{c=$3; sub("card[0-9]+-","",c); print c, b}' > "$M"; fi
read_all() { printf '{'; first=1; while read -r c b; do v=$(ddcutil -b "$b" --sleep-multiplier .5 getvcp 10 --brief 2>/dev/null | awk '{print $4}'); [ $first = 0 ] && printf ','; printf '"%s":%s' "$c" "${v:-100}"; first=0; done < "$M"; echo '}'; }
case "$1" in
  get)
    if [ -s "$C" ]; then cat "$C"; [ -n "$(find "$C" -mmin +10)" ] && { read_all > "$C.tmp" && mv "$C.tmp" "$C"; } >/dev/null 2>&1 &
    else read_all | tee "$C"; fi ;;
  set)
    b=$(awk -v c="$2" '$1==c{print $2}' "$M"); [ -n "$b" ] || exit 0
    python3 -I -c "import json,sys;p='$C'
try: d=json.load(open(p))
except Exception: d={}
d['$2']=int('$3'); json.dump(d,open(p,'w'))" 2>/dev/null
    ddcutil -b "$b" --noverify setvcp 10 "$3" >/dev/null 2>&1 ;;
esac
