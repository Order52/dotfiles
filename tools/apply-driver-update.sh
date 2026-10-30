#!/bin/bash
# sudo bash tools/apply-driver-update.sh
# Rebuild + reload the patched driver and the daemon on an installed system. Also repairs a system where the module is missing.
# Safe order: build for the RUNNING kernel first; only if that works is the running module swapped. The fan service is always restarted.
set -u
REPO=$(cd "$(dirname "$0")/.." && pwd)
SRC=/usr/src/linuwu_sense-1.0
KV=$(uname -r)
trap 'systemctl start predator.service 2>/dev/null' EXIT

install -d "$SRC/src"
install -m 644 "$REPO/drivers/linuwu_sense/Makefile" "$REPO/drivers/linuwu_sense/dkms.conf" "$SRC/"
install -m 644 "$REPO/drivers/linuwu_sense/src/linuwu_sense.c" "$SRC/src/"
install -d /usr/local/lib/predator
install -m 755 "$REPO/local-bin/predator-daemon.py" /usr/local/lib/predator/predator-daemon.py
dkms status linuwu_sense/1.0 2>/dev/null | grep -q . || dkms add linuwu_sense/1.0 >/dev/null 2>&1

ok=1
for k in /usr/lib/modules/*/build; do
  kv=$(basename "$(dirname "$k")"); [ -d "$k/include" ] || continue
  if dkms install linuwu_sense/1.0 -k "$kv" --force >/dev/null 2>&1; then echo "built for $kv"
  else echo "BUILD FAILED for $kv (see /var/lib/dkms/linuwu_sense/1.0/build/make.log)"; [ "$kv" = "$KV" ] && ok=0; fi
done
[ "$ok" = 1 ] || { echo "Build for the running kernel failed - NOT touching the loaded module."; exit 1; }

systemctl stop predator.service           # hands the fans back to firmware first
rmmod linuwu_sense 2>/dev/null || true
depmod -a
modprobe linuwu_sense || { echo "modprobe failed"; exit 1; }
systemd-tmpfiles --create /etc/tmpfiles.d/linuwu_sense.conf /etc/tmpfiles.d/acer-platform-profile.conf /etc/tmpfiles.d/predator-tuning.conf 2>/dev/null
systemctl start predator.service
sleep 4
echo "module: $(modinfo -F filename linuwu_sense)"
echo "profile: $(cat /sys/firmware/acpi/platform_profile 2>&1)   fan: $(cat /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed 2>&1)"
journalctl -k --since "-30s" --no-pager | grep -i linuwu | tail -6
echo "predator.service: $(systemctl is-active predator.service)"
