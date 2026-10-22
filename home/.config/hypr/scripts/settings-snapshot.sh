#!/usr/bin/env bash
# settings-snapshot.sh save|restore|list – keeps dated copies of your settings (Settings → Comfort). Made by Claude.
D="$HOME/.local/state/settings-snapshots"; S="$HOME/.config/hypr/settings.json"; mkdir -p "$D"
case "$1" in
  save)    cp "$S" "$D/settings-$(date +%Y-%m-%d_%H-%M-%S).json"; ls -1t "$D" | tail -n +21 | sed "s|^|$D/|" | xargs -r rm -f   # keep 20
           notify-send -a Settings "Settings saved" "snapshot $(date +%H:%M) · $(ls "$D" | wc -l) kept" ;;
  restore) f=$(ls -1t "$D"/*.json 2>/dev/null | head -1); [ -n "$f" ] || { notify-send -a Settings "No snapshot yet"; exit 1; }
           cp "$f" "$S" && "$HOME/.config/hypr/scripts/apply-settings.sh" && qs -p "$HOME/.config/quickshell/bar" ipc call settings reload 2>/dev/null
           notify-send -a Settings "Settings restored" "from $(basename "$f" .json | sed 's/settings-//')" ;;
  list)    ls -1t "$D" 2>/dev/null ;;
esac
