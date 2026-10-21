#!/usr/bin/env bash
# Backs up game saves from every Steam Proton prefix + Steam Cloud local copies.
# Output: ~/Games/InternalDrive/SaveBackups/saves-<date>.tar.zst (keeps the newest 14). Made by Claude.
set -euo pipefail
DEST="$HOME/Games/InternalDrive/SaveBackups"; KEEP=14; MAXMB=500
LIBS=("$HOME/.local/share/Steam/steamapps" "$HOME/Games/InternalDrive/SteamLibrary/steamapps")
SKIP='^(Microsoft|Temp|Unity|dxvk|NVIDIA Corporation|CrashReportClient|UnrealEngine|Packages|D3DSCache|mesa_shader_cache|My Music|My Pictures|My Videos|Downloads)$'
mkdir -p "$DEST"; LIST=$(mktemp); trap 'rm -f "$LIST"' EXIT
for lib in "${LIBS[@]}"; do
  for u in "$lib"/compatdata/*/pfx/drive_c/users/steamuser; do
    [ -d "$u" ] || continue
    for sub in "AppData/Roaming" "AppData/Local" "AppData/LocalLow" "Documents" "Saved Games"; do
      [ -d "$u/$sub" ] || continue
      for d in "$u/$sub"/*; do
        [ -d "$d" ] && [ ! -L "$d" ] || continue
        n=$(basename "$d"); [[ "$n" =~ $SKIP ]] && continue
        mb=$(du -sm "$d" | cut -f1)
        if [ "$mb" -gt "$MAXMB" ]; then echo "skip (${mb} MB, probably a cache): $d"; continue; fi
        echo "$d" >> "$LIST"
      done
    done
  done
done
for r in "$HOME"/.local/share/Steam/userdata/*/*/remote; do [ -d "$r" ] && echo "$r" >> "$LIST"; done
OUT="$DEST/saves-$(date +%Y-%m-%d_%H%M).tar.zst"
tar --zstd -cf "$OUT" --absolute-names --ignore-failed-read -T "$LIST" 2>/dev/null || true
echo "saved $(wc -l < "$LIST") folders -> $OUT ($(du -h "$OUT" | cut -f1))"
ls -1t "$DEST"/saves-*.tar.zst | tail -n +$((KEEP+1)) | xargs -r rm -f
