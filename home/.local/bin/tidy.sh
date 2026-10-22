#!/usr/bin/env bash
# tidy.sh – monthly clean-up of things that only pile up: old thumbnails, AUR build leftovers, trash older than
# 30 days, cache files nobody touched in 90 days (game shader caches are kept), and old screenshots' temp files.
# Shows how much it freed. Runs from tidy.timer; also from Settings → Comfort → Tidy now. Made by Claude.
before=$(df --output=used -B1M "$HOME" | tail -1)
find "$HOME/.cache/thumbnails" -type f -atime +30 -delete 2>/dev/null
find "$HOME/.cache/yay" -mindepth 1 -maxdepth 1 -mtime +14 -exec rm -rf {} + 2>/dev/null
find "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null
find "$HOME/.cache" -type f -atime +90 \
     -not -path "*/mesa_shader_cache*" -not -path "*/radv_builtin_shaders*" -not -path "*/qs-wall-thumbs/*" -not -path "*/nvidia/*" \
     -delete 2>/dev/null
find "$HOME/.cache" -mindepth 1 -type d -empty -delete 2>/dev/null
after=$(df --output=used -B1M "$HOME" | tail -1)
freed=$(( before - after )); [ $freed -lt 0 ] && freed=0
notify-send -a Tidy "System tidied" "freed ${freed} MB · next run in a month" 2>/dev/null
echo "freed ${freed}M"
