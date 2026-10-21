# yu's CachyOS dotfiles

Hyprland (Lua config) + custom Quickshell bar + Tokyo Night everywhere. Made with Claude.

| Folder | What |
|---|---|
| `home/.config/hypr` | Hyprland config (DMS-style keybinds, SUPER+F1 shows them), hyprlock, hypridle, hyprpaper, scripts |
| `home/.config/quickshell/bar` | Custom bar: workspaces, clock + weather + calendar, system stats, volume menu + OSD, media, notifications, power, Alt+Tab, wallpaper picker |
| `home/.config/{rofi,kitty,alacritty,MangoHud,fontconfig}` | App configs |
| `home/.config/{pipewire,wireplumber}` | Low-latency audio, Fuxi-H3 headset keep-alive |
| `home/.local/share/sddm-themes/tokyo-night-yu` | Login screen theme |
| `home/Downloads/Optiv10` | OptiScaler defaults + installer (DLLs not included) |
| `system/` | Copies of /etc files (login, scheduler, GPU 160 W cap, CPU 4.2 GHz cap, package cache cleanup) |

**Save changes:** `~/dotfiles/sync.sh "what I changed"`

**Restore on a fresh install:** copy `home/*` into `~` (`rsync -a home/ ~/`), and `sudo cp -r system/etc/* /etc/`,
then install the packages: `hyprland quickshell rofi kitty hyprlock hypridle hyprpaper hyprsunset hyprpicker grim slurp
wl-clipboard cliphist playerctl network-manager-applet hyprpolkitagent xdg-desktop-portal-hyprland sddm`.
