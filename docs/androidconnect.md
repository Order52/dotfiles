# Android phone in Noctalia

Bar button + panel for your phone, built on KDE Connect, with adb/scrcpy for the screen.

This is a native **Luau port** of
[demencia89/noctalia-shell-androidconnect-plugin](https://github.com/demencia89/noctalia-shell-androidconnect-plugin).
That plugin is QML for Noctalia 4 (Quickshell), and Noctalia 5 only loads Luau plugins (`plugin_api 3`), so it can't be
used directly. The main difference: the mirror opens in its own scrcpy window, not inside the panel (no v4l2loopback needed).

| File | What |
|---|---|
| `local-share/noctalia-plugins/androidconnect/` | plugin `sloppy/androidconnect`: widget `phone`, panel `panel` |
| `local-bin/androidconnect` | helper that does the work (KDE Connect over D-Bus, adb, scrcpy); usable from a terminal |
| `config/noctalia/config.toml` | `[widget.phone]`, placed in capsule group `g4` next to the battery |

## Bar button
* Shows the selected phone's battery % (and the number of notifications); grey phone icon when offline.
* **Click**: panel · **Right click**: ring the phone · **Middle click**: mirror the screen.

## Panel
* Device picker (all paired phones), battery / notifications / mobile signal.
* KDE Connect: **Ring**, **Send files** (file picker), **Browse** (SFTP mount, needs `sshfs`), **Clipboard** (sends this PC's clipboard).
* Screen (needs USB debugging): **Mirror** (scrcpy window, keeps the phone awake, phone screen off),
  **Screenshot** (`~/Pictures/Phone`, also copied to the clipboard), **Record** (click again to stop),
  **Keep awake** (`svc power stayon`), **Wi-Fi adb** (switches a USB-connected phone to wireless adb on its KDE Connect IP).

## Setup
1. Install the KDE Connect app on the phone and pair it (`kdeconnect-app` on the PC, or from the phone).
2. For the screen features: Developer options → USB debugging, plug in over USB once and accept the prompt.
   Then **Wi-Fi adb** lets you unplug it (works until the phone reboots).

## Terminal / IPC
```
androidconnect status              # id|name|reachable|charge|charging|notifications|nettype|signal|selected|recording|awake
androidconnect ring | mirror | screenshot | record | send | browse | clip | awake | wifi   [device-id]
noctalia msg plugin sloppy/androidconnect:phone all mirror
```
Extra scrcpy flags: `ANDROIDCONNECT_SCRCPY_ARGS`; output folder: `ANDROIDCONNECT_DIR`.
