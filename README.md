# yu's Arch: install guide

Vanilla Arch + Hyprland + Noctalia, minimal and **monochrome**, tuned to be **fast** like CachyOS, **safe** like Debian
and **secure** like Fedora. Follow the steps in order, on your phone, while you install. Made by Claude.

---

## Step 0: before you start

- ✅ Your games and pictures are on the **Games** drive (the 500 GB MSI). The install only wipes the **1 TB** drive.
- ✅ The Arch ISO is on your Ventoy USB stick (`archlinux-2026.10.01`).
- 🔌 Plug in the **Ethernet cable** (easiest). Wi-Fi works too, see the tip in step 2.

---

## Step 1: boot the USB

1. Plug in the USB stick and restart the PC.
2. Press **F11** (or F12, or F8, depending on your board) during startup for the boot menu, then pick the **USB** (UEFI).
3. In Ventoy, pick **archlinux-2026.10.01-x86_64.iso** → **Boot in normal mode**.
4. Pick the first option, **Arch Linux install medium**. You get a black screen with `root@archiso ~ #`.

---

## Step 2: install with archinstall

Wi-Fi only? Type `iwctl`, then `station wlan0 connect "YourWifiName"`, enter the password, then `exit`.

Type **`archinstall`** and press Enter. Go through the menu with the arrow keys and Enter, and set exactly this:

| Menu item | What to pick |
|---|---|
| **Archinstall language** | English |
| **Mirrors** | Mirror region → **Turkey** (and **Germany**) |
| **Locales** | Keyboard layout **trq** · Locale language **en_US.UTF-8** · Encoding **UTF-8** |
| **Disk configuration** | Partitioning → **Use a best-effort default partition layout** → select **only the 1 TB drive** (`/dev/nvme0n1`, ~931 GB): ⚠️ NOT the 500 GB one → filesystem **btrfs** → use subvolumes **Yes** → compression **Yes**. If it asks about snapshots → **Snapper** |
| **Disk encryption** | Leave off (or turn it on if you want a password at every boot) |
| **Bootloader** | **Limine** |
| **Unified kernel images** | No |
| **Swap** | **zram: Yes** |
| **Hostname** | `yu` |
| **Root password** | leave empty |
| **User account** | Add a user → name **`yu`**, your password, **superuser: Yes** |
| **Profile** | **Minimal** (no desktop; the setup adds yours) |
| **Audio** | **Pipewire** |
| **Kernels** | select **linux-zen** and **linux-lts** (unselect plain `linux`) |
| **Network configuration** | **Use NetworkManager** |
| **Additional packages** | `git` |
| **Optional repositories** | **multilib** |
| **Timezone** | **Europe/Istanbul** |
| **Automatic time sync** | Yes |

Then pick **Install** and confirm. It takes about 5–15 minutes.

When it asks **"chroot into the installation?"** → **No**. Then type **`reboot`** and pull out the USB stick.

---

## Step 3: first boot, run the setup

You get a text login (this is normal, no desktop yet).

1. Log in: type `yu`, Enter, then your password (it shows nothing while you type; that's normal).
2. Type these three lines, each followed by Enter:

```
git clone https://github.com/Shinimi/dotfiles ~/dotfiles
bash ~/dotfiles/arch/setup.sh
reboot
```

The setup runs on its own for about 15–30 minutes. It asks for your password a few times. If it ever asks
"Proceed?" or "[Y/n]", press **Enter**.

---

## Step 4: after the reboot

- You get the login screen → type your password → **Hyprland + Noctalia**.
- **Steam:** open it, log in → **Settings → Storage → ＋ → `/mnt/games/SteamLibrary`**. All your games are back without downloading.
- **This Claude chat:** open the Claude app and log in. The chat that built all this is restored; carry on there.
- **Weather:** Noctalia settings → Location → your city (kept out of this public repo).
- Keys: **SUPER + Space** apps · **SUPER + T** terminal · **SUPER + A** control center · **SUPER + 1-0** workspaces.

---

## If something goes wrong

- **The setup stopped with an error:** run `bash ~/dotfiles/arch/setup.sh` again; it continues where it can.
- **An app didn't install:** the end of the setup lists it; run `paru -S <name>`.
- **After an update something is broken:** restart → in the boot menu open **Snapshots** → pick the one from before the
  update. Or pick **linux-lts** in the boot menu.
- **No internet after install:** type `nmtui` and connect.
- **Discord won't connect** (blocked in Turkey): ask Claude to set up zapret2 (config in `system/opt/zapret2/`).

---

<details>
<summary>What's in this repo</summary>

| Folder | What |
|---|---|
| `arch/` | **The new setup**: `setup.sh`, `tune.sh` (fast / safe / secure), Hyprland + Noctalia configs, zsh, `CONTEXT.md` (for Claude) |
| `home/`, `system/`, `extras/` | The old CachyOS setup (Hyprland + custom Quickshell bar), kept for reference |
| `windows/` | A Windows 11 LTSC preset (not used) |

**fast:** zen kernel, CachyOS's LAVD gaming scheduler, CachyOS's own memory/disk/CPU tweaks, NTSYNC, amd-pstate ·
**safe:** LTS fallback kernel, a snapshot before and after every update (bootable), Arch news before updates, automatic mirrors/cache/trim ·
**secure:** firewall, AppArmor, kernel + network hardening, encrypted DNS, out-of-memory killer, firmware updates

</details>
