#!/bin/sh
# busiest.sh – the 5 apps using the most CPU over the last second (all its processes added up): "name cpu% rss-KiB".
# Used by the control center's System card. Made by Claude.
top -b -n 2 -d 1 -e k -w 512 | awk '/^top -/{n++} n==2 && $1 ~ /^[0-9]+$/ {c[$12]+=$9; m[$12]+=$6}
  END{for(k in c) if(m[k]>0 && k!="top" && k!="awk" && k!="qs" && k!="busiest.sh") printf "%s %.1f %d\n",k,c[k],m[k]}' | sort -k2 -nr | head -5
