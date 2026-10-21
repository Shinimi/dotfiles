#!/usr/bin/env bash
# Install Optiv10 into a game.  Usage:
#   bash install-optiv10.sh "<folder with the game's -Shipping.exe or main .exe>" [dll-name] [FGInput]
#   dll-name: dxgi.dll (default) | winmm.dll | version.dll | dbghelp.dll
#   FGInput : auto (default) | upscaler | fsrfg | fsrfg30 | dlssg | xefg
# Anything it replaces is copied to <game folder>/_optiv10_backup_<date>/ first.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="${1:?give the game exe folder}"; DLL="${2:-dxgi.dll}"; FGIN="${3:-auto}"
[ -d "$DST" ] || { echo "not a folder: $DST"; exit 1; }
ls "$DST"/*.exe >/dev/null 2>&1 || echo "warning: no .exe in $DST (Unreal games: use <Game>/Binaries/Win64)"
BK="$DST/_optiv10_backup_$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK"
for f in "$DLL" OptiScaler.ini OptiScaler amdxcffx64.dll amdvkffx64.dll; do [ -e "$DST/$f" ] && cp -a "$DST/$f" "$BK/"; done
cp -f "$SRC/OptiScaler.dll" "$DST/$DLL"
mkdir -p "$DST/OptiScaler"; cp -rf "$SRC/OptiScaler/." "$DST/OptiScaler/"
cp -f "$SRC/amdxcffx64.dll" "$SRC/amdvkffx64.dll" "$DST/"
cp -f "$SRC/OptiScaler.ini" "$DST/OptiScaler.ini"
[ "$FGIN" != auto ] && sed -i "s/^FGInput=.*/FGInput=$FGIN/" "$DST/OptiScaler.ini"
[ "$FGIN" = upscaler ] && sed -i '0,/^Enabled=auto/s//Enabled=true/' "$DST/OptiScaler.ini"
rmdir "$BK" 2>/dev/null || echo "backup: $BK"
echo "Optiv10 installed as $DLL in $DST (FGInput=$FGIN). In game: pick DLSS/FSR/XeSS, press INSERT to check."
