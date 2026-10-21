#!/usr/bin/env bash
# Rebuilds yu's CachyOS + Hyprland Shinobu Kochō setup on a fresh install. Made by Claude.
#
#   git clone https://github.com/Shinimi/dotfiles ~/dotfiles && ~/dotfiles/install.sh
#
# Safe to run again: existing files are backed up to ~/.dotfiles-backup-<date> before being replaced.
# It asks before each big step. Nothing here types passwords for you; sudo asks when it needs to.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
B="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
blue=$'\e[38;2;122;162;247m'; purple=$'\e[38;2;187;154;247m'; green=$'\e[38;2;158;206;106m'; dim=$'\e[38;2;86;95;137m'; off=$'\e[0m'
step() { printf '\n%s━━ %s%s\n' "$blue" "$1" "$off"; }
ask()  { read -rp "${purple}?${off} $1 [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
ok()   { printf '%s✓%s %s\n' "$green" "$off" "$1"; }

[ "$EUID" -eq 0 ] && { echo "Run this as your normal user, not root."; exit 1; }
command -v pacman >/dev/null || { echo "This needs an Arch-based system (CachyOS)."; exit 1; }

printf '%s\n  Shinobu Kochō · Hyprland · CachyOS\n%s  restoring from %s\n' "$blue" "$dim" "$R$off"

# ---------------------------------------------------------------- packages
PKGS=(
  # desktop
  hyprland hyprlock hypridle hyprpaper hyprsunset hyprpicker hyprpolkitagent xdg-desktop-portal-hyprland
  quickshell qt6-5compat qt6-svg kitty rofi sddm
  # tools the bar and shortcuts use
  network-manager-applet cliphist wl-clipboard wtype grim slurp playerctl libnotify jq rsync imagemagick pacman-contrib power-profiles-daemon
  # sound
  pipewire wireplumber pavucontrol noise-suppression-for-voice
  # look
  papirus-icon-theme capitaine-cursors adw-gtk-theme ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji plymouth
  # terminal & gaming
  fish starship fastfetch chafa btop mangohud scx-tools ddcutil
  # apps
  vesktop-bin git github-cli
)
AUR=(spicetify-cli)

step "Packages"
echo "${dim}${PKGS[*]}${off}"
if ask "Install/update these from the official repos?"; then
  sudo pacman -S --needed "${PKGS[@]}"
  ok "packages"
fi
if command -v yay >/dev/null && ask "Install AUR packages (${AUR[*]})?"; then
  yay -S --needed "${AUR[@]}"; ok "AUR packages"
fi

# ---------------------------------------------------------------- your files
step "Config files"
if ask "Copy configs into your home folder? (old files go to $B)"; then
  mkdir -p "$B"
  rsync -a --backup --backup-dir="$B" "$R/home/" "$HOME/"
  chmod +x "$HOME"/.local/bin/*.sh "$HOME"/.config/hypr/scripts/*.sh "$HOME"/.config/quickshell/bar/*.sh 2>/dev/null || true
  # Waterfox theme goes into whatever profile this install created
  wf=$(ls -d "$HOME"/.waterfox/*.default-release 2>/dev/null | head -1 || true)
  if [ -n "$wf" ] && [ -d "$R/extras/waterfox" ]; then rsync -a "$R/extras/waterfox/" "$wf/"; ok "Waterfox theme"; fi
  ok "configs (backup: $B)"
fi

# ---------------------------------------------------------------- system files
step "System tweaks"
echo "${dim}login screen, scheduler, boot splash, weekly cache cleanup, GPU 160 W cap, CPU boost cap${off}"
echo "${dim}(the GPU/CPU caps are tuned for a Ryzen 7 5700X + RX 9060 XT)${off}"
if ask "Install system files (needs sudo)?"; then
  sudo rsync -a --backup --suffix=".before-dotfiles" "$R/system/" /
  sudo systemctl daemon-reload
  sudo systemctl enable --now scx_loader.service 2>/dev/null || true
  if ask "  Enable the GPU power cap and CPU boost cap?"; then
    sudo systemctl enable --now amdgpu-power-cap.service cpu-boost-cap.service
  fi
  sudo systemctl enable sddm.service 2>/dev/null || true
  if [ -d /usr/share/plymouth/themes/shinobu ] && ask "  Use the Shinobu boot splash? (rebuilds the boot image)"; then
    sudo plymouth-set-default-theme -R shinobu
  fi
  ok "system files"
fi

# ---------------------------------------------------------------- services & theme
step "Services and theme"
systemctl --user daemon-reload
for u in audio-fx.service spicetify-refresh.service remember-volume.service backup-game-saves.timer weekly-checkup.timer fixfuxi-volume.timer hypr-doctor.timer; do
  [ -f "$HOME/.config/systemd/user/$u" ] && systemctl --user enable "$u" >/dev/null 2>&1 && ok "$u"
done
# headset volume fix also runs whenever the Fuxi-H3 is plugged in
systemctl --user add-wants 'dev-snd-by\x2did-usb\x2dXiiSound_Technology_Corporation_Fuxi\x2dH3\x2d00.device' fixfuxi-volume.service >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme capitaine-cursors 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
command -v plasma-apply-colorscheme >/dev/null && plasma-apply-colorscheme ShinobuKocho >/dev/null 2>&1 || true
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
  kwriteconfig6 --file kdeglobals --group General --key ColorScheme ShinobuKocho
  kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
fi
command -v spicetify >/dev/null && { spicetify config current_theme ShinobuKocho >/dev/null 2>&1; spicetify backup apply -q -n >/dev/null 2>&1 || true; }
[ "$(basename "${SHELL:-}")" = fish ] || { ask "Make fish your shell?" && chsh -s /usr/bin/fish; }
[ -f "$HOME/.face.icon" ] && "$HOME/.local/bin/fetch-logo.sh"
ok "theme"

printf '\n%sAll done.%s Log out and pick Hyprland on the login screen.\n' "$green" "$off"
printf '%sSUPER+A control center · SUPER+, settings · SUPER+V clipboard · SUPER+F1 all shortcuts%s\n\n' "$dim" "$off"
