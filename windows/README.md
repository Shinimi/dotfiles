# Windows 11 IoT Enterprise LTSC 2024: yu's preset

A Windows install that comes out clean and set up: no Microsoft account, no ads or suggestions, telemetry off, your apps
installed, and the same habits as the Linux setup (dark + grey, flat mouse, NumLock on). Made by Claude.

| File | What it does |
|---|---|
| `autounattend.xml` | Answers Windows Setup: English Windows, **Turkish Q keyboard**, Turkish date formats, Istanbul time, local account only, privacy questions all "off". **It never picks or wipes a drive: Setup asks you.** |
| `setup.ps1` | Runs by itself on first login: installs winget, your apps, game runtimes, League; then debloat + tweaks. Log in `C:\yu-setup.log`. |

## What you get

- **Apps:** Steam, Vesktop (Discord), Spotify, Brave, Waterfox, Windows Terminal, PowerShell 7, fastfetch, 7-Zip, VLC,
  Everything (instant file search), PowerToys, Windhawk (taskbar/look tweaks), OBS, Heroic, League of Legends (TR).
  Edit the `$apps` list at the top of `setup.ps1` to add or drop any (`winget search <name>` finds IDs).
- **Game runtimes:** Visual C++ 2015+ (x64/x86), DirectX, .NET 8 Desktop.
- **Debloat:** telemetry off, no ads/suggestions/"tips", no silently installed apps, no Bing in Start, no activity history,
  no update peer-sharing, no restarts while you're logged in, OneDrive removed (if present).
- **Look:** dark mode, grey accent, taskbar on the left with no Task View/Widgets/Copilot, search as an icon, file
  extensions + hidden files shown, Explorer opens on This PC, the full right-click menu, "End task" on taskbar right-click.
- **Input:** mouse acceleration off (like `accel_profile = flat`), NumLock on at boot, no Sticky Keys pop-up.
- **Gaming:** Game Mode on, Game DVR off, hardware GPU scheduling on, Ultimate Performance power plan, hibernation and
  fast startup off (also keeps the clock and the Linux drive happy if you dual-boot).

## Before you start

1. **BIOS:** turn on **TPM 2.0** (AMD: *fTPM*) and **Secure Boot**. League's Vanguard won't run on Windows 11 without them.
2. **The ISO:** Windows 11 IoT Enterprise LTSC 2024. Microsoft's Evaluation Center offers it as a 90-day trial; a full
   license comes through a device maker/reseller. Have your product key ready if you have one.
3. **Back up** anything on the drive you'll install to. The Linux setup itself is in this repo.

## Make the USB (from Linux, with Ventoy)

Ventoy boots ISOs straight from a stick and can hand Setup the answer file. **This wipes the USB stick**, so check the
device name first (`lsblk`).

```bash
sudo pacman -S ventoy-bin
lsblk                                   # find the stick, e.g. /dev/sdb (NOT your nvme drives)
sudo ventoy -i /dev/sdX                 # installs Ventoy on the stick (wipes it)
```

Then copy onto the stick's big partition (it mounts as "Ventoy"):

```
Win11_IoT_LTSC_2024.iso              ← the ISO, any name
win-setup/autounattend.xml           ← from this folder
win-setup/setup.ps1                  ← from this folder
ventoy/ventoy.json                   ← below
```

`ventoy/ventoy.json`:

```json
{ "auto_install": [ { "image": "/Win11_IoT_LTSC_2024.iso", "template": "/win-setup/autounattend.xml" } ] }
```

(Use the ISO's real file name in `"image"`.)

## Install

1. Boot the stick (F11/F12 boot menu on most boards), pick the ISO, then pick **"Boot with autounattend.xml"**.
2. Setup asks **which drive**: choose the one for Windows (e.g. the 500 GB MSI). Leave the Linux NVMe alone.
3. Make your local account when asked. On first login `setup.ps1` starts by itself (keep the stick plugged in).
4. When it finishes: install **AMD Software (Adrenalin)** for the RX 9060 XT (it opens the page), then restart.

Didn't start? Run `win-setup\setup.ps1` from the stick in an admin PowerShell:
`powershell -ExecutionPolicy Bypass -File D:\win-setup\setup.ps1` (with the stick's drive letter).
