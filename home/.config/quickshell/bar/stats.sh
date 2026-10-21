#!/usr/bin/env bash
# One JSON line of system stats for the bar. Made by Claude.
st="${XDG_RUNTIME_DIR:-/tmp}/qsbar-cpu"
read -r _ u n s i w x y z _ < /proc/stat; tot=$((u+n+s+i+w+x+y+z)); idle=$((i+w))
cpu=0; if [ -f "$st" ]; then read -r pt pi < "$st"; dt=$((tot-pt)); [ $dt -gt 0 ] && cpu=$(( (100*(dt-(idle-pi)))/dt )); fi
echo "$tot $idle" > "$st"
mt=$(awk '/MemTotal/{print $2}' /proc/meminfo); ma=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
ctemp=$(( $(cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input) / 1000 ))
freq=$(awk '{s+=$1;n++} END{printf "%.1f", s/n/1000000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
g=""; for d in /sys/class/drm/card*/device; do [ "$(cat $d/vendor)" = 0x1002 ] && { g=$d; break; }; done
gpu=$(cat $g/gpu_busy_percent); h=$(echo $g/hwmon/hwmon*)
gtemp=$(( $(cat $h/temp1_input) / 1000 )); gclk=$(( $(cat $h/freq1_input 2>/dev/null || echo 0) / 1000000 )); gpow=$(( $(cat $h/power1_average 2>/dev/null || cat $h/power1_input) / 1000000 ))
vu=$(cat $g/mem_info_vram_used); vt=$(cat $g/mem_info_vram_total)
# network speed (bytes/s) on the default interface, from the delta since the last run
ifc=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+'); ns="${XDG_RUNTIME_DIR:-/tmp}/qsbar-net"
rx=$(cat /sys/class/net/$ifc/statistics/rx_bytes 2>/dev/null || echo 0); tx=$(cat /sys/class/net/$ifc/statistics/tx_bytes 2>/dev/null || echo 0); now=$(date +%s%N)
netrx=0; nettx=0; if [ -f "$ns" ]; then read -r prx ptx pt < "$ns"; dt=$(( (now-pt)/1000000 )); [ $dt -gt 0 ] && { netrx=$(( (rx-prx)*1000/dt )); nettx=$(( (tx-ptx)*1000/dt )); }; fi
echo "$rx $tx $now" > "$ns"
up=$(awk '{d=int($1/86400); h=int($1%86400/3600); m=int($1%3600/60); if(d>0) printf "%dd %dh %dm",d,h,m; else printf "%dh %dm",h,m}' /proc/uptime)
awk -v cpu=$cpu -v ct=$ctemp -v fq=$freq -v mt=$mt -v ma=$ma -v gpu=$gpu -v gt=$gtemp -v gp=$gpow -v gc=$gclk -v vu=$vu -v vt=$vt -v up="$up" -v nrx=$netrx -v ntx=$nettx -v ifc="$ifc" 'BEGIN{
  printf "{\"cpu\":%d,\"cpuTemp\":%d,\"cpuFreq\":%s,\"ramUsed\":%.1f,\"ramTotal\":%.1f,\"ram\":%d,\"gpu\":%d,\"gpuTemp\":%d,\"gpuPower\":%d,\"gpuClock\":%.2f,\"vramUsed\":%.1f,\"vramTotal\":%.1f,\"uptime\":\"%s\",\"netRx\":%d,\"netTx\":%d,\"iface\":\"%s\"}\n",
    cpu, ct, fq, (mt-ma)/1048576, mt/1048576, 100*(mt-ma)/mt, gpu, gt, gp, gc/1000, vu/1073741824, vt/1073741824, up, nrx, ntx, ifc }'
