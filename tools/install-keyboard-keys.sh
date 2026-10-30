#!/bin/bash
# sudo bash tools/install-keyboard-keys.sh — lets your user read the keyboard's raw reports so Fn+F11 / Fn+F12 change the RGB brightness
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
install -m 644 "$REPO/system/etc/udev/rules.d/99-rgbkb-hidraw.rules" /etc/udev/rules.d/
udevadm control --reload
udevadm trigger --subsystem-match=hidraw --action=change
sleep 1
ls -l /dev/hidraw1 /dev/hidraw2 /dev/hidraw3 /dev/hidraw4 2>/dev/null
echo "done - Fn+F11 / Fn+F12 now change the keyboard brightness"
