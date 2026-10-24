#!/bin/sh
# mic-check.sh – records 3 s from your current mic (Clean mic if it's on), says how loud it was, then plays it back.
# Prints one word per step for the control center: rec, level=<0..1 peak>, play, done. Made by Claude.
f="${XDG_RUNTIME_DIR:-/tmp}/mic-check.wav"
echo rec
timeout 3 pw-record --rate 48000 --channels 1 --format s16 "$f" 2>/dev/null
python3 -I - "$f" <<'PY'
import wave,struct,sys,math
w=wave.open(sys.argv[1]); fr=w.readframes(w.getnframes())
v=struct.unpack("<%dh"%(len(fr)//2),fr) if fr else (0,)
peak=max(abs(x) for x in v)/32768
print("level=%.3f"%peak, flush=True)
PY
echo play
pw-play "$f" 2>/dev/null
echo done
