#!/bin/bash
# sudo bash tools/apply-driver-update.sh   — rebuild + reload the patched driver and the daemon on an already installed system.
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
SRC=/usr/src/linuwu_sense-1.0
install -m 644 "$REPO/drivers/linuwu_sense/Makefile" "$REPO/drivers/linuwu_sense/dkms.conf" "$SRC/"
install -m 644 "$REPO/drivers/linuwu_sense/src/linuwu_sense.c" "$SRC/src/"
install -m 755 "$REPO/local-bin/predator-daemon.py" /usr/local/lib/predator/predator-daemon.py
for k in /usr/lib/modules/*/build; do
  kv=$(basename "$(dirname "$k")"); [ -d "$k/include" ] || continue
  dkms remove linuwu_sense/1.0 -k "$kv" >/dev/null 2>&1 || true
  if dkms install linuwu_sense/1.0 -k "$kv" >/dev/null 2>&1; then echo "built for $kv"; else echo "BUILD FAILED for $kv"; fi
done
# reload the running module: stop the service first (it hands the fans back to firmware), swap, start again
systemctl stop predator.service
rmmod linuwu_sense
modprobe linuwu_sense
systemctl start predator.service
sleep 3
echo "module: $(modinfo -F filename linuwu_sense)"
echo "profile: $(cat /sys/firmware/acpi/platform_profile)  fan: $(cat /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed)"
journalctl -k --since "-20s" --no-pager | grep -i linuwu | tail -6
systemctl is-active predator.service
