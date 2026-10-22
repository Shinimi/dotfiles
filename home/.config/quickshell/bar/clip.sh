#!/usr/bin/env bash
# clip.sh list|paste <id>|pastetext <text>|pastefile <image>|pinimg <image>|delete <id>|wipe – helper for the clipboard panel.
# Made by Claude.
C="$HOME/.cache/qs-clip"; mkdir -p "$C"
P="$HOME/.local/state/clip-pins"; mkdir -p "$P"
send_paste() {   # paste into whatever window has focus (terminals want Ctrl+Shift+V)
  sleep 0.2
  cls=$(hyprctl activewindow -j | python3 -I -c 'import json,sys;print(json.load(sys.stdin).get("class",""))' 2>/dev/null)
  case "$cls" in kitty|Alacritty|foot|org.wezfurlong.wezterm|dropterm) wtype -M ctrl -M shift v -m shift -m ctrl ;; *) wtype -M ctrl v -m ctrl ;; esac
}
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
    send_paste ;;
  pastetext) printf '%s' "$2" | wl-copy; send_paste ;;
  pastefile) wl-copy < "$2"; send_paste ;;
  pinimg)    f="$P/$(date +%s%N).png"; cp "$2" "$f" && echo "$f" ;;   # keep a pinned picture even after the history is wiped
  delete)
    line=$(cliphist list | awk -F'\t' -v id="$2" '$1==id' | head -1); [ -n "$line" ] && printf '%s\n' "$line" | cliphist delete; rm -f "$C/$2.png" ;;
  wipe) cliphist wipe; rm -f "$C"/*.png ;;
esac
