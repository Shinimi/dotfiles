#!/usr/bin/env bash
# Counts pending updates (repo + AUR). Made by Claude.
r=$(checkupdates 2>/dev/null | wc -l); a=$(yay -Qua 2>/dev/null | wc -l)
printf '{"repo":%d,"aur":%d,"total":%d}\n' "$r" "$a" $((r+a))
