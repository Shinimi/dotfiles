#!/usr/bin/env bash
# safe-update.sh – system update with a safety net. Made by Claude.
#  · snap-pac already snapshots the system before/after (shown in the boot menu → Snapshots)
#  · afterwards it checks Hyprland's config and the top bar still load, and tells you if a reboot is needed
pink=$'\e[38;2;227;158;192m'; vio=$'\e[38;2;162;138;232m'; ok=$'\e[38;2;143;214;184m'; bad=$'\e[38;2;236;111;143m'; dim=$'\e[38;2;128;122;156m'; off=$'\e[0m'
printf '\n%s󱖉  Kochō update%s\n%s   A snapshot is taken automatically before anything changes.%s\n\n' "$pink" "$off" "$dim" "$off"
kernel_before=$(uname -r)
yay -Syu || { printf '\n%s✗ Update stopped – nothing else was changed.%s\n' "$bad" "$off"; read -n1 -rsp "press any key to close"; exit 1; }
printf '\n%s── checking your desktop ──%s\n' "$vio" "$off"
fail=0
if Hyprland --verify-config 2>&1 | tail -1 | grep -q "config ok"; then printf '%s✓%s Hyprland config loads\n' "$ok" "$off"; else printf '%s✗%s Hyprland config has errors\n' "$bad" "$off"; fail=1; fi
pkill -f "[q]s -p $HOME/.config/quickshell/bar"; sleep 8      # run.sh restarts the bar with the new packages
if qs log -p "$HOME/.config/quickshell/bar" 2>/dev/null | head -20 | grep -q "Configuration Loaded"; then printf '%s✓%s top bar loads\n' "$ok" "$off"; else printf '%s✗%s top bar fails to load\n' "$bad" "$off"; fail=1; fi
[ -d "/usr/lib/modules/$kernel_before" ] || { printf '%s!%s new kernel installed – reboot when convenient\n' "$pink" "$off"; }
if [ $fail = 1 ]; then
  printf '\n%sSomething broke.%s Reboot, choose %sSnapshots%s in the boot menu and pick the one from before this update.\n' "$bad" "$off" "$pink" "$off"
  notify-send -u critical -a "Kochō update" "Update finished with problems" "Reboot and pick the pre-update snapshot in the boot menu."
else
  printf '\n%sAll good.%s\n' "$ok" "$off"; notify-send -a "Kochō update" "Update finished" "Everything checks out."
fi
read -n1 -rsp "press any key to close"
