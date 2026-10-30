#!/bin/bash
# sudo bash tools/capture-keyboard-reports.sh
# Records for 25 s everything the Acer keyboard / Acer hotkey devices send: key events (evdev) and raw USB HID reports.
# While it runs press Fn+F11, wait a second, Fn+F12, wait a second, then Fn+F11 again.
exec python3 - <<'PY'
import glob, os, select, time
fds = {}
for h in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
    try:
        if "04F2" in open(h + "/device/uevent").read().upper():
            fds[os.open("/dev/" + os.path.basename(h), os.O_RDONLY | os.O_NONBLOCK)] = "hid:" + os.path.basename(h)
    except OSError:
        pass
evs = []
try:
    from evdev import InputDevice, ecodes as e, list_devices
    for p in list_devices():
        d = InputDevice(p)
        if any(k in d.name.lower() for k in ("acer", "keyboard", "hotkey", "wmi")) and e.EV_KEY in d.capabilities():
            evs.append(d); fds[d.fd] = "evdev:" + d.name
except Exception as ex:
    print("evdev unavailable:", ex)
print("listening on:", sorted(set(fds.values())), "\npress Fn+F11, Fn+F12, Fn+F11 now (25 s)", flush=True)
end = time.time() + 25
evmap = {d.fd: d for d in evs}
while time.time() < end:
    r, _, _ = select.select(list(fds), [], [], 0.5)
    for fd in r:
        if fd in evmap:
            for ev in evmap[fd].read():
                if ev.type == 1 and ev.value == 1:
                    from evdev import ecodes as e
                    print(f"{time.strftime('%T')} KEY {e.KEY.get(ev.code, ev.code)} (code {ev.code}) from {fds[fd]}", flush=True)
        else:
            try:
                data = os.read(fd, 64)
            except OSError:
                continue
            print(f"{time.strftime('%T')} {fds[fd]}: {data.hex(' ')}", flush=True)
print("done")
PY
