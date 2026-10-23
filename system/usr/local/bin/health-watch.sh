#!/bin/bash
# health-watch: weekly drive check (btrfs error counters + NVMe SMART). Writes a one-line verdict that
# the desktop reads and turns into a notification when something is wrong. Made by Claude.
out=/var/lib/health-watch/status; mkdir -p /var/lib/health-watch
bad=()
errs=$(btrfs device stats / 2>/dev/null | awk '$2>0{print $1" "$2}')
[ -n "$errs" ] && bad+=("btrfs errors: $(echo $errs)")
for d in /dev/nvme0n1 /dev/nvme1n1; do
  [ -e "$d" ] || continue
  h=$(smartctl -H "$d" 2>/dev/null | grep -c PASSED); w=$(smartctl -A "$d" 2>/dev/null | awk -F: '/Critical Warning/{gsub(/ /,"",$2);print $2}')
  [ "$h" = 1 ] && [ "${w:-0x00}" = 0x00 ] || bad+=("$d SMART warning")
  m=$(smartctl -A "$d" 2>/dev/null | awk -F: '/Media and Data Integrity Errors/{gsub(/ /,"",$2);print $2}')
  [ "${m:-0}" != 0 ] && bad+=("$d media errors: $m")
done
if [ ${#bad[@]} -eq 0 ]; then echo "ok $(date -Iseconds)" > "$out"; else echo "bad $(date -Iseconds) ${bad[*]}" > "$out"; fi
chmod 644 "$out"
