#!/bin/bash
# Run with:  sudo bash ~/tune-prep.sh
# 1. Stress tools for stability testing (GPU: vkmark, CPU: stress-ng).
# 2. Lets the `linuwu_sense` group (you) adjust CPU max frequency and power limits, so tuning can be tested
#    without a password each step. Nothing is changed yet; values stay at stock until tested.
set -e
pacman -S --needed --noconfirm vkmark stress-ng

cat > /etc/tmpfiles.d/predator-tuning.conf <<'EOF'
z /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq 0664 root linuwu_sense -
z /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 0664 root linuwu_sense -
z /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 0664 root linuwu_sense -
EOF
systemd-tmpfiles --create /etc/tmpfiles.d/predator-tuning.conf
ls -l /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
echo "ready - plug in the charger and tell Claude"
