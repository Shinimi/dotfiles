#!/usr/bin/env bash
# kb-colors.sh [kocho|violet|pink|off] – keyboard RGB in the Shinobu palette (AULA F87 Pro via OpenRGB). Made by Claude.
mode="${1:-kocho}"
n=$(openrgb -d 0 -ld 2>/dev/null | grep -o "'Key:[^']*'" | wc -l); n=${n:-90}
case "$mode" in
  off)    openrgb -d 0 -m off >/dev/null 2>&1; exit ;;
  violet) cols="A28AE8" ;;
  pink)   cols="E39EC0" ;;
  *)      cols=$(python3 -I -c "
n=$n; stops=[(162,138,232),(227,158,192),(127,196,227)]
out=[]
for i in range(n):
    t=i/max(1,n-1)*(len(stops)-1); a=int(t); b=min(a+1,len(stops)-1); f=t-a
    out.append('%02X%02X%02X'%tuple(int(stops[a][k]+(stops[b][k]-stops[a][k])*f) for k in range(3)))
print(','.join(out))") ;;
esac
openrgb -d 0 -m direct -c "$cols" >/dev/null 2>&1
