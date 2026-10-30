#!/usr/bin/env bash
# setup.sh – turns a fresh, minimal Arch install into yu's desktop: Hyprland + Noctalia (minimal, monochrome), only the
# apps you use, gaming ready, the Games drive (Steam library) mounted at /mnt/games, your wallpapers back. Then tune.sh
# makes it fast like CachyOS, safe like Debian and secure like Fedora.
# Run it once as your user (not root) after the first boot:  bash ~/dotfiles/arch/setup.sh
# It asks for your password (sudo) and prints each step. Safe to run again. Made by Claude.
set -euo pipefail
[ "$EUID" -eq 0 ] && { echo "Run it as your user, not root (it uses sudo where needed)."; exit 1; }
R="$(cd "$(dirname "$0")/.." && pwd)"     # the dotfiles repo
A="$R/arch"
step() { printf '\n\033[1;37m== %s\033[0m\n' "$*"; }

step "pacman: multilib (Steam), colours, parallel downloads"
sudo sed -i 's/^#Color/Color/; s/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
grep -q '^\[multilib\]' /etc/pacman.conf || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null

step "packages (official repos)"
pkgs=(
  # desktop: Hyprland + Noctalia, portals, Qt on Wayland, clipboard, login screen
  hyprland noctalia xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt6-wayland qt5-wayland polkit
  wl-clipboard cliphist greetd greetd-tuigreet
  # apps
  kitty dolphin ark spotify-launcher mpv btop fastfetch pavucontrol 7zip unzip
  pciutils playerctl nano xdg-utils xdg-user-dirs man-db
  # dark look for GTK and Qt apps (Dolphin…): adw-gtk3 + Breeze style, Papirus icons
  adw-gtk-theme breeze qt6ct papirus-icon-theme
  # shell
  zsh zsh-autosuggestions zsh-syntax-highlighting git base-devel
  # fonts
  ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-liberation
  # sound
  pipewire pipewire-pulse pipewire-alsa wireplumber
  # gaming (AMD RX 9060 XT)
  steam mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon mangohud lib32-mangohud gamescope lact
  # system
  zram-generator power-profiles-daemon
  # fast: kernels + CachyOS's gaming CPU scheduler
  linux-zen linux-zen-headers linux-lts amd-ucode scx-scheds scx-tools
  # safe: snapshots on every update, mirror + cache upkeep
  snapper snap-pac btrfs-assistant reflector pacman-contrib
  # secure: firewall, AppArmor, firmware updates
  ufw apparmor fwupd
)
sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"

step "paru (for the few AUR apps)"
if ! command -v paru >/dev/null; then
  t=$(mktemp -d); git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$t/paru-bin"
  (cd "$t/paru-bin" && makepkg -si --noconfirm); rm -rf "$t"
fi
mkdir -p ~/.config/paru; printf '[options]\nNewsOnUpgrade\nRemoveMake\nCleanAfter\n' > ~/.config/paru/paru.conf   # Arch news before every update
step "AUR apps: Vesktop, Brave, Helium, Waterfox, Claude, Powerlevel10k, your cursor, snapshot boot entries"
failed=()
for p in vesktop-bin brave-bin helium-browser-bin waterfox-bin zsh-theme-powerlevel10k vimix-cursors-git limine-snapper-sync claude-desktop; do
  paru -S --needed --noconfirm "$p" || failed+=("$p")
done
[ ${#failed[@]} -gt 0 ] && echo "!! these didn't install (run 'paru -S ${failed[*]}' later): ${failed[*]}"

step "services: login screen, power profiles, GPU control, compressed RAM swap"
sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1
[default_session]
command = "tuigreet --time --remember --asterisks --greeting 'arch' --cmd start-hyprland"
user = "greeter"
EOF
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\n' | sudo tee /etc/systemd/zram-generator.conf >/dev/null
sudo systemctl enable greetd power-profiles-daemon lactd

step "Games drive → /mnt/games (Steam library: /mnt/games/SteamLibrary)"
sudo mkdir -p /mnt/games
grep -q 'LABEL=Games' /etc/fstab || echo 'LABEL=Games  /mnt/games  ext4  defaults,noatime,nofail  0 2' | sudo tee -a /etc/fstab >/dev/null
sudo systemctl daemon-reload; sudo mount /mnt/games 2>/dev/null || true
sudo chown "$USER:$USER" /mnt/games

step "your configs"
mkdir -p ~/.config/hypr ~/.config/noctalia ~/.local/bin
cp "$A/hypr/hyprland.lua" ~/.config/hypr/hyprland.lua
cp "$A/noctalia/config.toml" ~/.config/noctalia/config.toml
cp "$A/zshrc" ~/.zshrc
for d in kitty fastfetch btop MangoHud mpv; do [ -d "$R/home/.config/$d" ] && cp -r "$R/home/.config/$d" ~/.config/; done
cp "$R/home/.p10k.zsh" ~/.p10k.zsh 2>/dev/null || true
cp "$R/home/.local/bin/frieren-fetch" ~/.local/bin/ 2>/dev/null || true
[ -f "$R/home/.face" ] && cp "$R/home/.face" ~/.face
sudo chsh -s /usr/bin/zsh "$USER"

step "dark GTK + Qt apps, Papirus icons, your cursor"
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/qt6ct
for v in 3.0 4.0; do
  cp "$R/home/.config/gtk-$v/gtk.css" ~/.config/gtk-$v/ 2>/dev/null || true      # your monochrome colours
  printf '[Settings]\ngtk-application-prefer-dark-theme=true\ngtk-theme-name=adw-gtk3-dark\ngtk-icon-theme-name=Papirus-Dark\ngtk-cursor-theme-name=Vimix-cursors-white\ngtk-cursor-theme-size=24\ngtk-font-name=Inter 10\n' > ~/.config/gtk-$v/settings.ini
done
cp "$R/home/.config/gtk-3.0/colors.css" ~/.config/gtk-3.0/ 2>/dev/null || true
cp "$R/home/.config/gtk-4.0/colors.css" ~/.config/gtk-4.0/ 2>/dev/null || true
printf '[Appearance]\nstyle=Breeze\ncustom_palette=true\ncolor_scheme_path=/usr/share/qt6ct/colors/darker.conf\nicon_theme=Papirus-Dark\n[Fonts]\ngeneral="Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"\nfixed="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"\n' > ~/.config/qt6ct/qt6ct.conf
mkdir -p ~/.icons/default; printf '[Icon Theme]\nInherits=Vimix-cursors-white\n' > ~/.icons/default/index.theme
xdg-user-dirs-update

step "wallpapers (from the Games drive backup)"
mkdir -p ~/Pictures
[ -d /mnt/games/home-backup/Pictures ] && cp -rn /mnt/games/home-backup/Pictures/. ~/Pictures/
[ -d /mnt/games/home-backup/Games ] && cp -rn /mnt/games/home-backup/Games ~/

step "your Claude conversations (from the Games drive backup)"
# the Claude app's data, with the chat that set all this up: open the app afterwards and carry on
[ -d /mnt/games/home-backup/claude/.claude ] && [ ! -e ~/.claude/projects ] && cp -a /mnt/games/home-backup/claude/.claude ~/
[ -d /mnt/games/home-backup/claude/Claude ] && [ ! -e ~/.config/Claude ] && cp -a /mnt/games/home-backup/claude/Claude ~/.config/

bash "$A/tune.sh" || echo "!! a tuning step failed (the desktop itself is set up): run 'bash ~/dotfiles/arch/tune.sh' again after reboot"

echo
echo "Done. Reboot: the login screen, then Hyprland + Noctalia."
echo "If an update ever breaks something: reboot, pick a snapshot in the boot menu."
echo "In Steam: Settings → Storage → add /mnt/games/SteamLibrary, and your games are back without downloading."
