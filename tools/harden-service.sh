#!/bin/bash
# sudo bash tools/harden-service.sh — extra "never dies" settings for predator.service on an installed system
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
install -d /etc/systemd/system/predator.service.d
install -m 644 "$REPO/system/etc/systemd/system/predator.service.d/10-never-die.conf" /etc/systemd/system/predator.service.d/
systemctl daemon-reload
systemctl restart predator.service
sleep 4
systemctl show predator -p Restart -p StartLimitIntervalUSec -p StartLimitBurst -p OOMScoreAdjust -p Nice -p CPUWeight -p ManagedOOMPreference -p WatchdogUSec | tr '\n' ' '; echo
echo "active: $(systemctl is-active predator)   oom_score_adj: $(cat /proc/$(systemctl show -p MainPID --value predator)/oom_score_adj)"
