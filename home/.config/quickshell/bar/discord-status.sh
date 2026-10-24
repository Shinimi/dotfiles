#!/bin/sh
# discord-status.sh – is the Discord fix (zapret2) running, and does Discord's live connection get through right now?
# Prints: svc=active|inactive net=ok|blocked. Used by the control center's System page. Made by Claude.
svc=$(systemctl is-active zapret2.service 2>/dev/null)
ok=0; for i in 1 2; do curl -s -o /dev/null -m 4 https://gateway.discord.gg/ && ok=$((ok+1)); done
echo "svc=$svc net=$([ $ok -ge 1 ] && echo ok || echo blocked)"
