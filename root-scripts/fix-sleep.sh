#!/bin/bash
# Run with:  sudo bash ~/fix-sleep.sh
set -e

# 1. NVIDIA suspend/resume hooks. Your kernel cmdline has NVreg_PreserveVideoMemoryAllocations=1,
#    but these services were disabled, so the GPU was never saved/restored -> black screen on wake.
systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service

# 2. Save VRAM to disk (/var/tmp) instead of /tmp, which is RAM (tmpfs) on this machine.
cat > /etc/modprobe.d/nvidia-sleep.conf <<'EOF'
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

# 3. Suspend first (fast wake, tiny drain), then hibernate after 30 min so the battery is not slowly drained.
mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
cat > /etc/systemd/sleep.conf.d/10-sleep.conf <<'EOF'
[Sleep]
MemorySleepMode=deep
HibernateDelaySec=30min
EOF
cat > /etc/systemd/logind.conf.d/10-lid.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF

# 4. nvidia modules are in the initramfs, so rebuild it to pick up the modprobe option.
mkinitcpio -P

echo "Done. Reboot, then test: systemctl suspend"
