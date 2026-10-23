#!/bin/bash
# Shows a notification when the weekly drive check (health-watch) found a problem. Each problem is
# announced once; a fresh "ok" clears it. Made by Claude.
s=/var/lib/health-watch/status; seen="$HOME/.local/state/health-notify.seen"
[ -r "$s" ] || exit 0
read -r verdict when rest < "$s"
[ "$verdict" = bad ] || { rm -f "$seen"; exit 0; }
[ "$(cat "$seen" 2>/dev/null)" = "$when" ] && exit 0
notify-send -u critical -a "Drive health" "A drive needs attention" "$rest — back up important files and check Settings → Storage."
mkdir -p "$(dirname "$seen")"; echo "$when" > "$seen"
