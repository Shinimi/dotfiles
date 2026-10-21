#!/usr/bin/env bash
# Keeps exactly one bar running. If it dies, starts it again – but never a second copy
# (Quickshell's own crash handler can revive it, so we check first). Made by Claude.
B="$HOME/.config/quickshell/bar"
while true; do
  if qs ipc -p "$B" show >/dev/null 2>&1; then sleep 5; continue; fi   # a bar is already up
  qs -p "$B"
  sleep 2
done
