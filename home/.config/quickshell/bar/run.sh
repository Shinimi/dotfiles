#!/usr/bin/env bash
# Keeps the bar running: restarts it within a second if it ever crashes. Made by Claude.
while true; do
  qs -p "$HOME/.config/quickshell/bar"
  [ $? -eq 0 ] && break      # normal quit: stop
  sleep 1
done
