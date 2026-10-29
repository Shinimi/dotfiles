#!/usr/bin/env bash
# usb-sounds.sh – a soft sound when a USB device is plugged in or pulled out (runs as a user service; uses
# kocho-sound.sh, so it follows Settings → Notifications → Sounds and stays quiet while you game). Made by Claude.
sleep 5   # skip the burst of devices appearing at login
udevadm monitor --udev --subsystem-match=usb/usb_device 2>/dev/null | while read -r src _ action _; do
  [ "$src" = UDEV ] || continue
  case "$action" in
    add)    "$HOME/.local/bin/kocho-sound.sh" device-added ;;
    remove) "$HOME/.local/bin/kocho-sound.sh" device-removed ;;
  esac
done
