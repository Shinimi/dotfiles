# Vanilla Arch: yu's minimal Hyprland + Noctalia (monochrome)

A fresh, clean Arch with only what you use: Hyprland + Noctalia (minimal, like TermNode's setup, in your black-and-white),
your apps, gaming ready, and your Steam library on the Games drive. Made by Claude.

| File | What |
|---|---|
| `setup.sh` | Run once after the install: packages, AUR apps, login screen, services, Games drive, configs, wallpapers |
| `hypr/hyprland.lua` | Minimal Hyprland: your screens, Turkish keyboard, flat mouse, monochrome glass, window rules, keys |
| `noctalia/config.toml` | Noctalia in monochrome (greys from the wallpaper, true black), clean floating bar, none on the side screen |
| `zshrc` | zsh with your Frieren fetch, Powerlevel10k, suggestions + highlighting |

## Before you start

- **Your Steam library, Games and Pictures are on the Games drive** (the 500 GB MSI, ext4, label `Games`). The install
  below wipes **only** the 1 TB main drive (`nvme0n1`). Don't touch `nvme1n1`.
- The Arch ISO is on your Ventoy stick (`archlinux-2026.10.01-x86_64.iso`, checksum verified).
- Plug in Ethernet (simplest), or set up Wi-Fi with `iwctl` in the installer.

## Install (≈15 minutes)

1. Boot the Ventoy stick (F11/F12 boot menu) → **archlinux-2026.10.01**.
2. At the prompt run `archinstall` and set:

| Menu | Choose |
|---|---|
| Mirrors | Region → **Turkey** (and Germany as a backup) |
| Locales | Keyboard **trq** · Language **en_US.UTF-8** · Encoding UTF-8 |
| Disk configuration | Use a best-effort default layout → **nvme0n1 (931 GB)** only → **btrfs** → use subvolumes **yes** → compression **yes** |
| Bootloader | **Limine** (or Systemd-boot) |
| Swap | **zram yes** |
| Hostname | `yu` |
| Root password | leave empty (sudo user below) |
| User account | **yu**, your password, **superuser yes** |
| Profile | **Minimal** (setup.sh adds Hyprland + Noctalia; don't pick a desktop here) |
| Audio | **Pipewire** |
| Kernels | **linux** (add **linux-zen** if you want a lower-latency gaming kernel too) |
| Network | **NetworkManager** |
| Timezone | **Europe/Istanbul** |
| Additional packages | `git` |
| Optional repositories | **multilib** |

3. **Install** → when it finishes, choose **no** for chroot, then `reboot` and pull the stick.

## After the first boot

You land on a text login. Log in as `yu`, then:

```bash
git clone -b niri-noctalia-and-updates https://github.com/Shinimi/dotfiles ~/dotfiles
bash ~/dotfiles/arch/setup.sh
reboot
```

Then: login screen → Hyprland + Noctalia. Open **Steam → Settings → Storage → add `/mnt/games/SteamLibrary`**, and every
game is back without downloading. Spotify: `spotify-launcher`. GPU fan/undervolt: **LACT** (in the launcher).
