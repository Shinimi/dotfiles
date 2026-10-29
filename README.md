# yu's CachyOS dotfiles

Hyprland (Lua config) + custom Quickshell bar, in **monochrome** (greys, white accents, black-and-white wallpapers).

**Branches:** `main` = monochrome · `shinobu` = Shinobu Kochō theme · `tokyo-night` = Tokyo Night.

| Folder | What |
|---|---|
| `home/.config/hypr` | Hyprland config (DMS-style keybinds, SUPER+F1 shows them), hyprlock, hypridle, hyprpaper, scripts |
| `home/.config/quickshell/bar` | Custom bar: workspaces, clock + weather + calendar, system stats, volume menu + OSD, media, notifications, power, Alt+Tab, wallpaper picker |
| `home/.config/{rofi,kitty,alacritty,MangoHud,fontconfig}` | App configs |
| `home/.config/{pipewire,wireplumber}` | Low-latency audio, Fuxi-H3 headset keep-alive |
| `home/.local/share/sddm-themes/tokyo-night-yu` | Login screen theme |
| `home/Downloads/Optiv10` | OptiScaler defaults + installer (DLLs not included) |
| `system/` | Copies of /etc files (login, scheduler, GPU 160 W cap, CPU 4.2 GHz cap, package cache cleanup, gpu-ctl fan modes + per-game GPU watts) + ASCII boot splash |
| `extras/waterfox` | Waterfox monochrome theme (userChrome) |
| `home/.local/share/{mono-chrome,mono-newtab}` | Helium/Brave monochrome theme + new tab page |

**Save changes:** `~/dotfiles/sync.sh "what I changed"`

**Restore on a fresh install:**

```bash
git clone https://github.com/Shinimi/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

The installer asks before each step (packages, configs, system tweaks, boot splash) and backs up anything it replaces
to `~/.dotfiles-backup-<date>`.

**Shortcuts:** SUPER+A control center · SUPER+, settings · SUPER+V clipboard · SUPER+. emoji · SUPER+G games ·
SUPER+Y wallpaper · SUPER+Alt+L lock · SUPER+F1 every shortcut
