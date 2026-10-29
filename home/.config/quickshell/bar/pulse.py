#!/usr/bin/env python3
# pulse.py – how loud the music is right now, 0..1, twenty times a second, for the bar's music pulse.
# Listens to what the speakers play (the default output's monitor), never the mic; the stream is named "qs peak"
# so the privacy indicator ignores it. Auto-gains, so quiet and loud songs both move the line. Made by Claude.
import subprocess, sys, struct, math
RATE, CHUNK = 8000, 400   # 50 ms
p = subprocess.Popen(["pw-record", "--rate", str(RATE), "--channels", "1", "--format", "s16",
                      "-P", '{ stream.capture.sink = true, node.name = "qs-peak-pulse", application.name = "qs peak", media.name = "qs peak" }', "-"],
                     stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
peak, level = 0.08, 0.0
try:
    while True:
        b = p.stdout.read(CHUNK * 2)
        if not b: break
        n = len(b) // 2
        s = struct.unpack("<%dh" % n, b[:n * 2])
        rms = math.sqrt(sum(x * x for x in s) / n) / 32768
        peak = max(rms, peak * 0.995, 0.02)                  # slowly forgetting loudest moment = auto-gain
        v = min(1.0, rms / peak)
        level = v if v > level else level * 0.78 + v * 0.22  # snap up on a beat, ease down
        sys.stdout.write("%.2f\n" % level); sys.stdout.flush()
except (BrokenPipeError, KeyboardInterrupt): pass
finally: p.kill()
