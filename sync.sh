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
  .config/systemd/user/audio-fx.service .config/systemd/user/spicetify-refresh.service
  .config/systemd/user/weekly-checkup.service .config/systemd/user/weekly-checkup.timer
  .local/bin/audio-fx.sh .local/bin/weekly-checkup.sh .local/bin/papirus-folders-color.sh .local/bin/hypr-doctor.sh .local/bin/gamemode.sh .local/bin/fetch-logo.sh .local/bin/fetch-ascii.sh .local/bin/recolor-theme.py .local/bin/retheme.py .local/bin/mono-icons.py .local/bin/kb-colors.sh .local/bin/safe-update.sh .local/bin/kocho-sound.sh .local/bin/frieren-fetch .local/bin/tidy.sh .config/systemd/user/tidy.service .config/systemd/user/tidy.timer .local/bin/health-notify.sh .config/systemd/user/health-notify.service .config/systemd/user/health-notify.timer .local/bin/mouse-battery.py .local/bin/sort-downloads.sh .config/systemd/user/sort-downloads.path .config/systemd/user/sort-downloads.service .config/qalculate/qalc.cfg
  .local/share/sounds/mono .local/share/sounds/kocho-voice/README.txt .local/share/Steam/millennium/themes/Material-Theme .config/millennium/config.json .local/share/applications/steam.desktop .config/MangoHud .config/millennium/quick.css .config/spotify-launcher.conf
  .config/vesktop-flags.conf .config/spotify-launcher.conf .config/limine-theme
  .config/systemd/user/hypr-doctor.service .config/systemd/user/hypr-doctor.timer
  .config/spicetify/Themes/Monochrome .config/vesktop/settings/quickCss.css
  .config/gtk-3.0/settings.ini .config/gtk-3.0/gtk.css .config/gtk-4.0/settings.ini .config/gtk-4.0/gtk.css
  .local/share/color-schemes/Monochrome.colors .icons/default/index.theme
  .config/starship.toml .config/fastfetch .config/btop .config/fish/config.fish .zshrc .p10k.zsh
  .local/share/mono-chrome .local/share/mono-newtab .config/heroic/themes .config/helium-browser-flags.conf .config/environment.d .local/state/settings-snapshots
  .config/systemd/user/fixfuxi-volume.service .config/systemd/user/fixfuxi-volume.timer fixfuxi
  .config/OpenRGB .config/mimeapps.list .config/swaync .config/user-dirs.dirs
  Games/OptiScaler-Endfield-backup-2026-10-24/OptiScaler.ini
  Downloads/Optiv10/OptiScaler.ini Downloads/Optiv10/README-Optiv10.txt Downloads/Optiv10/install-optiv10.sh
  .config/niri .config/noctalia .config/mpv .config/brave-origin-flags.conf .local/share/org.kde.syntax-highlighting .face
  .local/bin/game-session.sh .local/bin/usb-sounds.sh
  .config/systemd/user/rates-refresh.service .config/systemd/user/rates-refresh.timer
  .config/systemd/user/pkgwatch.service .config/systemd/user/pkgwatch.timer .config/systemd/user/usb-sounds.service
)
system_paths=(
  /etc/sddm.conf.d/10-mono-yu.conf /etc/sddm.conf.d/10-tokyo-night-yu.conf /etc/scx_loader.toml
  /usr/local/bin/gpu-ctl /etc/systemd/system/gpu-fan.service
  /etc/systemd/system/amdgpu-power-cap.service /etc/systemd/system/cpu-boost-cap.service
  /etc/systemd/system/paccache.service.d/keep2.conf
  /etc/systemd/system/health-watch.service /etc/systemd/system/health-watch.timer /usr/local/bin/health-watch.sh
  /etc/udev/rules.d/70-yu-battery.rules /opt/zapret2/config /opt/zapret2/ipset/zapret-hosts-user.txt
  /usr/share/plymouth/themes/mono /usr/share/plymouth/themes/ascii /usr/share/sddm/themes/mono-yu
)
for p in "${home_paths[@]}"; do
  [ -e "$H/$p" ] || continue
  mkdir -p "$R/home/$(dirname "$p")"
  rsync -a --delete --exclude '*.old' --exclude '*.before-*' --exclude '*.log' --exclude '.git' "$H/$p" "$R/home/$(dirname "$p")/"
done
for p in "${system_paths[@]}"; do
  [ -r "$p" ] || continue
  mkdir -p "$R/system$(dirname "$p")"; rsync -a --delete "$p" "$R/system$(dirname "$p")/"
done
# Waterfox theme (profile folder name differs per install)
wf=$(ls -d "$H"/.waterfox/*.default-release 2>/dev/null | head -1)
if [ -n "$wf" ]; then mkdir -p "$R/extras/waterfox"; rsync -a --delete "$wf/chrome" "$R/extras/waterfox/"; cp -a "$wf/user.js" "$R/extras/waterfox/" 2>/dev/null; fi
# package lists for a reinstall
mkdir -p "$R/packages"; pacman -Qqen > "$R/packages/native.txt"; pacman -Qqem > "$R/packages/aur.txt"
cd "$R"
git add -A
if git diff --cached --quiet; then echo "nothing changed"; exit 0; fi
git commit -qm "${1:-sync $(date '+%Y-%m-%d %H:%M')}"
echo "committed: $(git log -1 --format='%h %s')"
git remote get-url origin >/dev/null 2>&1 && git push -q && echo "pushed to $(git remote get-url origin)" || true
