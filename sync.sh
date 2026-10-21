#!/usr/bin/env bash
# Copies yu's configs into this repo and commits (and pushes, if a remote is set). Made by Claude.
# Usage:  ~/dotfiles/sync.sh ["optional message"]
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"; H="$HOME"
home_paths=(
  .config/hypr .config/quickshell/bar .config/rofi .config/kitty .config/alacritty .config/waybar
  .config/MangoHud .config/fontconfig .config/pipewire .config/wireplumber
  .config/systemd/user/backup-game-saves.service .config/systemd/user/backup-game-saves.timer
  .config/systemd/user/remember-volume.service
  .local/bin/backup-game-saves.sh .local/bin/remember-volume.sh
  .local/share/sddm-themes/tokyo-night-yu
  Downloads/Optiv10/OptiScaler.ini Downloads/Optiv10/README-Optiv10.txt Downloads/Optiv10/install-optiv10.sh
)
system_paths=(
  /etc/sddm.conf.d/10-tokyo-night-yu.conf /etc/scx_loader.toml
  /etc/systemd/system/amdgpu-power-cap.service /etc/systemd/system/cpu-boost-cap.service
  /etc/systemd/system/paccache.service.d/keep2.conf
)
for p in "${home_paths[@]}"; do
  [ -e "$H/$p" ] || continue
  mkdir -p "$R/home/$(dirname "$p")"
  rsync -a --delete --exclude '*.old' --exclude '*.before-*' --exclude '*.log' "$H/$p" "$R/home/$(dirname "$p")/"
done
for p in "${system_paths[@]}"; do
  [ -r "$p" ] || continue
  mkdir -p "$R/system$(dirname "$p")"; cp -a "$p" "$R/system$p"
done
cd "$R"
git add -A
if git diff --cached --quiet; then echo "nothing changed"; exit 0; fi
git commit -qm "${1:-sync $(date '+%Y-%m-%d %H:%M')}"
echo "committed: $(git log -1 --format='%h %s')"
git remote get-url origin >/dev/null 2>&1 && git push -q && echo "pushed to $(git remote get-url origin)" || true
