#!/bin/bash
# Run with:  sudo bash ~/undervolt-check.sh
# Read-only check + one harmless -10 mV test that is reverted to 0 straight away. Changes nothing permanently.
set -u
pacman -S --needed --noconfirm intel-undervolt lact >/dev/null && echo "tools installed"
modprobe msr
CONF=/etc/intel-undervolt.conf
cp "$CONF" /etc/intel-undervolt.conf.orig

echo "== CPU: current offsets =="
intel-undervolt read

echo "== CPU: trying -10 mV =="
sed -i -E "s/^undervolt ([02]) '([^']+)' .*/undervolt \1 '\2' -10/" "$CONF"
intel-undervolt apply 2>&1
intel-undervolt read

echo "== CPU: reverting to 0 =="
cp /etc/intel-undervolt.conf.orig "$CONF"
intel-undervolt apply 2>&1
intel-undervolt read

echo "== GPU =="
systemctl enable --now lactd
sleep 2
nvidia-smi --query-gpu=name,driver_version,clocks.max.graphics --format=csv,noheader
echo "done"
