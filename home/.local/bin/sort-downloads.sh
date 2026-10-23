#!/usr/bin/env bash
# Sorts finished downloads into Images / Videos / Music / Documents / Archives / Installers and shows a
# notification for each one ("Open" / "Show in folder"). Runs whenever ~/Downloads changes (sort-downloads.path).
# Anything it doesn't recognise stays where it is. Off: Settings → Comfort. Made by Claude.
D=$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads"); SEEN="$XDG_RUNTIME_DIR/sort-downloads.seen"
sort_on=$(python3 -I -c "import json;print(json.load(open('$HOME/.config/hypr/settings.json')).get('sort_downloads', True))" 2>/dev/null)
touch "$SEEN"
sleep 1.5                                         # let the browser finish renaming / writing
folder_for() {
  case "${1,,}" in
    *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp|*.svg|*.avif|*.heic|*.tiff|*.ico) echo Images ;;
    *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v|*.wmv|*.flv) echo Videos ;;
    *.mp3|*.flac|*.wav|*.ogg|*.opus|*.m4a|*.aac|*.wma) echo Music ;;
    *.pdf|*.doc|*.docx|*.odt|*.txt|*.md|*.rtf|*.xls|*.xlsx|*.ods|*.csv|*.ppt|*.pptx|*.odp|*.epub) echo Documents ;;
    *.zip|*.rar|*.7z|*.tar|*.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.gz|*.xz|*.bz2|*.zst) echo Archives ;;
    *.exe|*.msi|*.appimage|*.deb|*.rpm|*.pkg.tar.zst|*.flatpakref|*.jar|*.run|*.sh) echo Installers ;;
  esac
}
notify() {   # $1 = final path, $2 = folder label
  ( act=$(notify-send -a Downloads -i folder-download -A open=Open -A show="Show in folder" -t 8000 \
            "$(basename "$1")" "${2:-Downloads}"); \
    case "$act" in open) xdg-open "$1" ;; show) dolphin --select "$1" 2>/dev/null || xdg-open "$(dirname "$1")" ;; esac ) >/dev/null 2>&1 &
}
shopt -s nullglob
for f in "$D"/*; do
  [ -f "$f" ] || continue
  n=$(basename "$f")
  case "$n" in .*|*.part|*.crdownload|*.tmp|*.download|*.!qB|*.opdownload|*.partial) continue ;; esac
  id="$(stat -c '%i:%Z' "$f")"; grep -qxF "$id" "$SEEN" && continue
  s1=$(stat -c %s "$f"); sleep 0.5; [ "$s1" = "$(stat -c %s "$f" 2>/dev/null)" ] || continue   # still growing
  sub=$(folder_for "$n")
  if [ "$sort_on" = True ] && [ -n "$sub" ]; then
    mkdir -p "$D/$sub"; t="$D/$sub/$n"; i=2
    while [ -e "$t" ]; do t="$D/$sub/${n%.*} ($i).${n##*.}"; i=$((i+1)); done
    mv -n "$f" "$t" && notify "$t" "→ $sub"
  else
    echo "$id" >> "$SEEN"; notify "$f" "Downloads"
  fi
done
