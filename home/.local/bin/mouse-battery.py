#!/usr/bin/env python3
# Prints the VXE mouse battery as JSON: {"percent": 87, "charging": false, "asleep": false}. While the mouse sleeps
# the dongle can't ask it, so the last known level comes back with "asleep": true; {} = no dongle at all.
# Talks to the 2.4 GHz dongle's vendor HID channel (report 8, command 3 = link status, 4 = power); the udev rule
# /etc/udev/rules.d/70-yu-battery.rules lets you read it without root. Made by Claude.
import glob, json, os, select, time

IDS = {("3554", "f58e"), ("3554", "f58f"), ("373b", "1085")}

def packet(cmd):
    p = bytearray(17); p[0] = 8; p[1] = cmd; p[16] = (0x55 - sum(p[:16])) & 0xFF
    return bytes(p)

def ask(fd, cmd):
    os.write(fd, packet(cmd)); end = time.time() + 0.6
    while time.time() < end:
        if select.select([fd], [], [], 0.2)[0]:
            d = os.read(fd, 64)
            if len(d) >= 17 and d[0] == 8 and d[1] == cmd: return d
    return None

def nodes():
    for h in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        ue = open(h + "/device/uevent").read()
        hid = next((l.split("=")[1] for l in ue.splitlines() if l.startswith("HID_ID=")), "")
        parts = hid.split(":")
        if len(parts) == 3 and (parts[1][-4:].lower(), parts[2][-4:].lower()) in IDS:
            yield "/dev/" + os.path.basename(h)

CACHE = os.path.expanduser("~/.local/state/mouse-battery.json")
out = {}; dongle = False
for dev in nodes():
    try: fd = os.open(dev, os.O_RDWR)
    except OSError: continue
    try:
        st = ask(fd, 3)
        if not st: continue
        dongle = True
        if st[6] == 0: break                       # dongle is there, mouse is asleep / off
        pw = ask(fd, 4)
        if pw and pw[6] <= 100: out = {"percent": pw[6], "charging": pw[7] == 1 and pw[6] < 100}; break
    except OSError: pass
    finally: os.close(fd)
if out:
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    json.dump(out, open(CACHE, "w")); out["asleep"] = False
elif dongle:
    try: out = json.load(open(CACHE)); out["asleep"] = True
    except Exception: out = {"asleep": True}
print(json.dumps(out))
