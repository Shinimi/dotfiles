#!/usr/bin/env bash
# rates.sh [refresh] – USD, EUR and GBP in Turkish lira (ECB rates via frankfurter.dev): today, the change since
# yesterday, and the last 7 working days for a little trend line. Cached in ~/.cache/qs-rates.json; refreshed when
# older than 3 hours (or with "refresh"), which also updates the launcher's own rates (= 5 usd to try). Made by Claude.
C="$HOME/.cache/qs-rates.json"
if [ "${1:-}" = refresh ] || [ ! -s "$C" ] || [ $(( $(date +%s) - $(stat -c %Y "$C") )) -gt 10800 ]; then
  from=$(date -d '-12 days' +%F)
  j=$(curl -s -m 10 "https://api.frankfurter.dev/v1/$from..?base=EUR&symbols=USD,TRY,GBP") && python3 -I -c '
import json, sys
d = json.loads(sys.argv[1]); days = sorted(d["rates"])[-7:]
def tl(day, cur):   # 1 <cur> in lira, from the EUR-based table
    r = d["rates"][day]; return r["TRY"] if cur == "EUR" else r["TRY"] / r[cur]
out = {"date": days[-1], "rates": []}
for cur, sign in (("USD", "$"), ("EUR", "€"), ("GBP", "£")):
    series = [round(tl(x, cur), 4) for x in days]
    out["rates"].append({"cur": cur, "sign": sign, "now": series[-1], "change": round(100 * (series[-1] / series[-2] - 1), 2), "series": series})
print(json.dumps(out))' "$j" > "$C.tmp" && [ -s "$C.tmp" ] && mv "$C.tmp" "$C"
  rm -f "$C.tmp"
  (timeout 20 qalc -e -t "1" >/dev/null 2>&1 &)   # the launcher's converter stays current too
fi
cat "$C" 2>/dev/null || echo '{"rates":[]}'
