#!/usr/bin/env bash
# clip.sh list|paste <id>|delete <id>|wipe – helper for the clipboard panel. Made by Claude.
C="$HOME/.cache/qs-clip"; mkdir -p "$C"
case "$1" in
  list)
    cliphist list 2>/dev/null | head -n 150 | while IFS=$'\t' read -r id txt; do
      if [[ "$txt" == "[[ binary data"* ]]; then
        f="$C/$id.png"; [ -s "$f" ] || printf '%s\t%s\n' "$id" "$txt" | cliphist decode > "$f" 2>/dev/null
        printf '%s\t1\t%s\t%s\n' "$id" "$f" "$(sed 's/\[\[ binary data //; s/ \]\]//' <<<"$txt")"
      else
        printf '%s\t0\t\t%s\n' "$id" "$txt"
      fi
    done
    # drop thumbnails of entries that are gone
    ls "$C" 2>/dev/null | while read -r f; do cliphist list | cut -f1 | grep -qx "${f%.png}" || rm -f "$C/$f"; done & ;;
  paste)
    line=$(cliphist list | awk -F'\t' -v id="$2" '$1==id' | head -1); [ -z "$line" ] && exit 1
    printf '%s\n' "$line" | cliphist decode | wl-copy
    sleep 0.2
    cls=$(hyprctl activewindow -j | python3 -I -c 'import json,sys;print(json.load(sys.stdin).get("class",""))' 2>/dev/null)
    case "$cls" in kitty|Alacritty|foot|org.wezfurlong.wezterm) wtype -M ctrl -M shift v -m shift -m ctrl ;; *) wtype -M ctrl v -m ctrl ;; esac ;;
  delete)
    line=$(cliphist list | awk -F'\t' -v id="$2" '$1==id' | head -1); [ -n "$line" ] && printf '%s\n' "$line" | cliphist delete; rm -f "$C/$2.png" ;;
  wipe) cliphist wipe; rm -f "$C"/*.png ;;
esac
