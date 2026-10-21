#!/usr/bin/env bash
# Weekly system check-up: disks, SSD health, failed services, updates, noisiest error sources.
# Sends one notification; "Details" opens the full report, "Update" updates. Made by Claude.
R="$HOME/.local/state/weekly-checkup.txt"; issues=()
{
echo "Weekly check-up – $(date '+%A %d %B %Y %H:%M')"; echo
echo "■ Disk space"
while read -r mp use avail; do echo "  $mp: ${use} used, ${avail} free"; [ "${use%\%}" -ge 85 ] && issues+=("$mp is ${use} full"); done < <(df -h --output=target,pcent,avail / "$HOME/Games/InternalDrive" 2>/dev/null | tail -n +2)
echo; echo "■ SSD health"
for d in $(busctl --system tree org.freedesktop.UDisks2 2>/dev/null | grep -oE '/org/freedesktop/UDisks2/drives/[A-Za-z0-9_]+' | sort -u); do
  m=$(busctl --system get-property org.freedesktop.UDisks2 $d org.freedesktop.UDisks2.Drive Model 2>/dev/null | cut -d'"' -f2)
  w=$(busctl --system get-property org.freedesktop.UDisks2 $d org.freedesktop.UDisks2.NVMe.Controller SmartCriticalWarning 2>/dev/null)
  t=$(busctl --system get-property org.freedesktop.UDisks2 $d org.freedesktop.UDisks2.NVMe.Controller SmartTemperature 2>/dev/null | awk '{print $2-273}')
  [ -z "$w" ] && continue
  if [ "$w" = "as 0" ]; then echo "  $m: OK (${t}°C)"; else echo "  $m: WARNING ($w)"; issues+=("SSD $m reports a warning"); fi
done
echo; echo "■ Failed services"
fs=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}'); fu=$(systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
if [ -z "$fs$fu" ]; then echo "  none"; else for u in $fs $fu; do echo "  $u"; done; issues+=("$(echo $fs $fu | wc -w) failed service(s)"); fi
echo; echo "■ Updates"
ur=$(checkupdates 2>/dev/null | wc -l); ua=$(yay -Qua 2>/dev/null | wc -l); echo "  repo: $ur, AUR: $ua"
echo; echo "■ Noisiest error sources this week"
journalctl -p 3 --since -7d -q --no-pager -o json 2>/dev/null | python3 -I -c "
import json,sys,collections
c=collections.Counter()
for l in sys.stdin:
    try: j=json.loads(l)
    except Exception: continue
    c[j.get('SYSLOG_IDENTIFIER') or j.get('_COMM') or '?']+=1
for k,v in c.most_common(5): print(f'  {k}: {v}')
" || echo "  (could not read the journal)"
echo; echo "■ Snapshots"; echo "  boot-menu snapshots are managed automatically by CachyOS (limine-snapper-sync)"
} > "$R"
upd=$((ur+ua))
summary="$( [ ${#issues[@]} -eq 0 ] && echo 'All good' || printf '%s · ' "${issues[@]}" | sed 's/ · $//')$( [ $upd -gt 0 ] && echo " · $upd updates waiting")"
acts=(--action=details=Details); [ $upd -gt 0 ] && acts+=(--action=update="Update now")
choice=$(notify-send -a "System check-up" -i dialog-information "  Weekly check-up" "$summary" "${acts[@]}" 2>/dev/null)
case "$choice" in
  details) kitty --class checkup -e sh -c "cat '$R'; echo; read -n1 -rsp 'Press any key to close'" ;;
  update)  kitty --class updater -e bash -c "yay -Syu; echo; read -n1 -rsp 'Done – press any key to close'" ;;
esac
