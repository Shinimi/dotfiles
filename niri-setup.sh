#!/usr/bin/env bash
# niri-setup.sh – adds a Niri + Noctalia session next to Hyprland, with the same keys, screens, rules and monochrome
# look. Hyprland stays as it is; you pick "Niri" on the login screen (and can go back any time).
#
#   ~/dotfiles/niri-setup.sh
#
# Note: the right Noctalia is the `noctalia` package (the native v5 shell). Do NOT install `noctalia-shell`: on
# CachyOS that package ships only source code and replaces Quickshell, which the Hyprland bar needs. Made by Claude.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
echo "── Installing Niri, Noctalia and Xwayland support (asks for your password)"
sudo pacman -S --needed niri noctalia xwayland-satellite
echo "── Configs"
mkdir -p "$HOME/.config/niri" "$HOME/.config/noctalia"
rsync -a --backup --suffix=".before-dotfiles" "$R/home/.config/niri/" "$HOME/.config/niri/"
rsync -a --backup --suffix=".before-dotfiles" "$R/home/.config/noctalia/" "$HOME/.config/noctalia/"
niri validate -c "$HOME/.config/niri/config.kdl" && noctalia config validate "$HOME/.config/noctalia/config.toml"
echo
echo "Done. Log out, pick \"Niri\" on the login screen. SUPER+F1 lists every key; SUPER+, opens Noctalia's settings."
