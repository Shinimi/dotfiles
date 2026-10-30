# Vanilla Arch: yu's ultimate minimal setup

A fresh, clean Arch with only what you use: Hyprland + Noctalia (minimal, like TermNode's setup, in your black-and-white),
your apps, gaming ready, your Steam library on the Games drive, and:

- **fast like CachyOS:** zen kernel, CachyOS's gaming CPU scheduler (LAVD), CachyOS's own memory/disk/CPU tweaks, NTSYNC for Proton, the modern Ryzen frequency driver
- **safe like Debian:** an LTS fallback kernel, a snapshot before and after every update that you can boot from the menu, Arch news shown before each update, mirrors/cache/SSD kept healthy automatically
- **secure like Fedora:** firewall, AppArmor, kernel and network hardening, encrypted DNS, out-of-memory killer, firmware updates

Made by Claude. Read this on your phone while you install: it's the `arch/README.md` page of the dotfiles repo on GitHub.

| File | What |
|---|---|
| `setup.sh` | Run once after the install: packages, AUR apps, login screen, services, Games drive, configs, wallpapers; runs `tune.sh` |
| `tune.sh` | The fast / safe / secure part (re-runnable on its own) |
| `hypr/hyprland.lua` | Minimal Hyprland: your screens, Turkish keyboard, flat mouse, monochrome glass, window rules, keys |
| `noctalia/config.toml` | Noctalia in monochrome (greys from the wallpaper, true black), clean floating bar, none on the side screen |
| `zshrc` | zsh with your Frieren fetch, Powerlevel10k, suggestions + highlighting |
| `CONTEXT.md` | Where things stand, your preferences, what's left: for continuing with Claude |

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
| Disk configuration | Use a best-effort default layout → **nvme0n1 (931 GB)** only → **btrfs** → use subvolumes **yes** → compression **yes** (if it asks about snapshots: **Snapper**) |
| Bootloader | **Limine** (needed for booting into snapshots) |
| Swap | **zram yes** |
| Hostname | `yu` |
| Root password | leave empty (sudo user below) |
| User account | **yu**, your password, **superuser yes** |
| Profile | **Minimal** (setup.sh adds Hyprland + Noctalia; don't pick a desktop here) |
| Audio | **Pipewire** |
| Kernels | **linux-zen** + **linux-lts** (zen = fast gaming kernel, lts = the safe fallback if zen ever breaks) |
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

**Carry on with Claude:** setup.sh installs the Claude app and puts back its data from the Games drive, so the chat that
built all this is still there; open it and keep going. For a fresh chat, say: *"read arch/CONTEXT.md in my dotfiles"*.

## If an update ever breaks something

Every update makes a snapshot before and after. Reboot → in the boot menu open **Snapshots** → pick the one from before
the update → it boots and restores. Or use **Btrfs Assistant** (in the launcher). If the zen kernel misbehaves, pick
**linux-lts** in the boot menu.

**Updating:** `paru` (shows Arch news first, then updates everything, snapshots included).

## Discord in Turkey

Discord is blocked by Turkish ISPs. Encrypted DNS (already on) fixes some of it; if Discord still won't connect, your old
fix (zapret2) can be set up again: its config is in `system/opt/zapret2/` of this repo.
