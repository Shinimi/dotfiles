#!/usr/bin/env bash
# netdoctor.sh – the control center's connection check. Tests the link, the internet, DNS (and whether it's encrypted),
# then Discord, Steam and YouTube, and says in plain words what's wrong. Prints one JSON line. Made by Claude.
ok() { [ "$1" = 1 ] && echo true || echo false; }
link=0; ip route get 1.1.1.1 >/dev/null 2>&1 && link=1
ping=$(ping -c 2 -W 2 -q 1.1.1.1 2>/dev/null | awk -F/ '/rtt/{printf "%d", $5}'); net=0; [ -n "$ping" ] && net=1
dns=0; enc=0; q=$(resolvectl query cloudflare.com 2>/dev/null) && dns=1; echo "$q" | grep -q 'encrypted transport: yes' && enc=1
[ $dns = 0 ] && getent hosts cloudflare.com >/dev/null 2>&1 && dns=1
site() {   # reachable = any HTTP answer at all; prints "1 <ms>" or "0 0"
  r=$(curl -s -o /dev/null -m 6 -w '%{http_code} %{time_total}' "$1" 2>/dev/null); c=${r%% *}; t=${r##* }
  [ -n "$c" ] && [ "$c" != 000 ] && awk -v t="$t" 'BEGIN{printf "1 %d", t*1000}' || echo "0 0"
}
read -r dc dct < <(site https://gateway.discord.gg/)
read -r st stt < <(site https://store.steampowered.com/)
read -r yt ytt < <(site https://www.youtube.com/)
zap=$(systemctl is-active zapret2.service 2>/dev/null); systemctl cat zapret2.service >/dev/null 2>&1 || zap=missing
# the verdict: the first thing that's broken, in plain words
if   [ $link = 0 ]; then say="No network: the cable or Wi-Fi isn't connected."
elif [ $net = 0 ];  then say="Connected to the router, but the internet doesn't answer. Restart the modem, or your provider is down."
elif [ $dns = 0 ];  then say="Internet works, but names don't resolve (DNS). Try: resolvectl flush-caches, or reconnect."
elif [ $dc = 0 ] && [ "$zap" != active ]; then say="Discord is blocked by your provider. Turn on the Discord fix (the switch on the right)."
elif [ $dc = 0 ];   then say="Discord is blocked even with the fix on. Restart the fix, or Discord's servers are down."
elif [ $st = 0 ] || [ $yt = 0 ]; then say="Most things work, but $( [ $st = 0 ] && echo Steam)$( [ $st = 0 ] && [ $yt = 0 ] && echo ' and ')$( [ $yt = 0 ] && echo YouTube) don't load right now."
elif [ "${ping:-0}" -gt 80 ]; then say="Everything works, but ping is high (${ping} ms): something may be downloading."
else say="Everything works."; fi
printf '{"link":%s,"net":%s,"ping":%d,"dns":%s,"encrypted":%s,"discord":%s,"discordMs":%d,"steam":%s,"steamMs":%d,"youtube":%s,"youtubeMs":%d,"zapret":"%s","say":"%s"}\n' \
  $(ok $link) $(ok $net) "${ping:-0}" $(ok $dns) $(ok $enc) $(ok $dc) "$dct" $(ok $st) "$stt" $(ok $yt) "$ytt" "$zap" "$say"
