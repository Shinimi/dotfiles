# Context for Claude (and for yu): where things stand

Hand this file to a new Claude chat ("read arch/CONTEXT.md in my dotfiles") to carry on where we left off. The full
conversation is also backed up on the Games drive (`/mnt/games/home-backup/claude`) and restored by `setup.sh`, so the
Claude app can simply reopen it. Last updated 31 October 2026. Made by Claude.

## The machine

- AMD Ryzen 7 5700X · AMD Radeon RX 9060 XT (16 GB) · 32 GB RAM
- Main drive 1 TB NVMe (`nvme0n1`, the system) · second 500 GB MSI NVMe (`nvme1n1`, ext4, label **Games**, mounted at `/mnt/games`)
- Screens: DP-1 2560×1440 @ 144 Hz (main, left) · DP-2 1920×1080 @ 165 Hz (side, right)
- Turkish Q keyboard, mouse flat at 0.4, middle-button scrolling · in Turkey (Discord is blocked there)
- Also a Windows laptop (plays League of Legends there: Vanguard can't run on Linux, and streaming it to Linux fails
  because Vanguard ignores injected mouse input)

## What yu likes (keep these)

- **Monochrome** everything: greys, white accents, black-and-white wallpapers. Tried purple, green/Everforest, mint:
  went back to monochrome every time.
- Minimal, clean, no bloat; "make it look good, not broken"; glass/transparency is liked when text stays readable.
- Workspace switching is the thing he uses most. No bar on the side screen. Games truly fullscreen (no bar over them).
- Wants things checked before they're declared done, and wants backups before risky changes.
- Speaks Turkish natively, writes casual English; keep answers short and in plain words.

## Where it's going

Moving from CachyOS (heavily customised Hyprland + a custom Quickshell bar) to **vanilla Arch** with a minimal
**Hyprland + Noctalia** setup in monochrome (inspired by TermNode's "Noctalia Made Me Stop Ricing" video), tuned to be fast
like CachyOS, safe like Debian, secure like Fedora. Everything is in `arch/` (README = the install guide).

Before the reinstall:
- All game data was copied to the Games drive: `/mnt/games/SteamLibrary/steamapps` (Warframe, Wuthering Waves,
  Persona 3 Reload, DragonSword, Dark Souls R, JoJo ASBR, Hero Siege, Moon Sweepers + Proton), plus
  `home-backup/` (Pictures incl. wallpapers, ~/Games, Steam userdata, the Claude app data).
- The old CachyOS setup is in this repo (`home/`, `system/`, branch `niri-noctalia-and-updates`).

## After the reinstall: still to do

1. In Steam: Settings → Storage → add `/mnt/games/SteamLibrary`.
2. Check every game launches (Wuthering Waves had a half-finished update: Steam resumes it).
3. GPU: LACT for fan curve / undervolt (on CachyOS it ran at −50 mV, fine).
4. Discord: if it won't connect, set up zapret2 again (config in `system/opt/zapret2/`).
5. The Arch scripts haven't run on real hardware yet: if anything in `setup.sh` / `tune.sh` misbehaves, fix it in the repo.

## Lessons learned (so they don't repeat)

- Never `pkill -f <pattern>` when the pattern is in your own command line: it kills the shell running it.
- zsh doesn't word-split `$var`: wrap multi-word commands in `bash -c` or use arrays.
- Background helpers started under a held `flock` inherit the lock: start them with `9>&-` (this broke game mode once).
- Spicetify colours only change after `spicetify apply`; browser themes after a restart (delete `Cached Theme.pak`).
- Niri's blur can't darken like Hyprland's: bright wallpapers wash out glass windows.
- Recolouring a theme: keep each grey's brightness and only change the hue, or text loses contrast.
