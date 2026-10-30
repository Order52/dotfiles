#!/bin/bash
# Run with:  sudo bash ~/install-predator.sh
# Installs the Predator brain as a root system service: starts at boot (before login), survives logout and
# session crashes, cannot be killed by user processes, restarts itself, is health-checked by an independent timer,
# and is re-armed by hooks on suspend/resume and on package updates (kernel, nvidia, dkms, python, systemd).
set -e
USER_NAME=sloppy
SRC=/home/$USER_NAME/.local/bin/predator-daemon.py

# 1. root-owned copy of the daemon (a user-owned file in $HOME must not be what the root service executes)
install -d -m 755 /usr/local/lib/predator
install -m 755 -o root -g root "$SRC" /usr/local/lib/predator/predator-daemon.py

# 2. main service
cat > /etc/systemd/system/predator.service <<EOF
[Unit]
Description=Predator smart fan curve, thermal governor and profile auto
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=notify
NotifyAccess=main
WatchdogSec=15
Environment=PREDATOR_USER=$USER_NAME
ExecStartPre=-/usr/bin/modprobe linuwu_sense
ExecStart=/usr/bin/python3 -u /usr/local/lib/predator/predator-daemon.py
# however it ends (crash, kill, hang, stop, update): fans back to firmware control, clocks uncapped
ExecStopPost=/bin/sh -c 'echo 0,0 > /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed; for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq; do echo 5000000 > \$f; done; true'
Restart=always
RestartSec=1
Nice=-10
OOMScoreAdjust=-1000
MemoryMin=32M
ProtectHome=read-only
ReadWritePaths=/home/$USER_NAME/.cache /tmp
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF

# 3. independent health check (second layer, separate from the watchdog): stale state or missing module -> fix + restart
cat > /usr/local/lib/predator/health.sh <<'EOF'
#!/bin/bash
FAN=/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed
[ -e "$FAN" ] || modprobe linuwu_sense 2>/dev/null
if ! systemctl is-active --quiet predator.service; then
  systemctl restart predator.service; exit 0
fi
age=$(( $(date +%s) - $(stat -c %Y /tmp/predator-state 2>/dev/null || echo 0) ))
if [ "$age" -gt 20 ]; then
  logger -t predator-health "state file stale (${age}s), restarting predator.service"
  systemctl restart predator.service
fi
EOF
chmod 755 /usr/local/lib/predator/health.sh
cat > /etc/systemd/system/predator-health.service <<'EOF'
[Unit]
Description=Predator health check
[Service]
Type=oneshot
ExecStart=/usr/local/lib/predator/health.sh
EOF
cat > /etc/systemd/system/predator-health.timer <<'EOF'
[Unit]
Description=Predator health check every 30 s
[Timer]
OnBootSec=60
OnUnitActiveSec=30
AccuracySec=1s
[Install]
WantedBy=timers.target
EOF

# 4. suspend / resume: fans to firmware before sleep, fresh state (caches cleared, clocks re-applied) after wake
cat > /usr/lib/systemd/system-sleep/predator <<'EOF'
#!/bin/sh
case "$1" in
  pre)  echo 0,0 > /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed 2>/dev/null ;;
  post) systemctl restart --no-block predator.service ;;
esac
exit 0
EOF
chmod 755 /usr/lib/systemd/system-sleep/predator

# 5. package updates: re-arm after anything that can touch it (kernel / dkms module, nvidia, python, systemd)
mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/predator-rearm.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux*
Target = *dkms*
Target = nvidia*
Target = linuwu*
Target = python
Target = systemd
Target = lact

[Action]
Description = Re-arming predator fan service...
When = PostTransaction
Exec = /bin/sh -c 'modprobe linuwu_sense 2>/dev/null; systemctl daemon-reload; systemctl try-restart predator.service lactd.service; true'
EOF

# 6. retire the user-level copy so only one brain runs
sudo -u $USER_NAME XDG_RUNTIME_DIR=/run/user/$(id -u $USER_NAME) systemctl --user disable --now predator.service 2>/dev/null || true

# 7. make sure the module loads at every boot
grep -qs linuwu_sense /etc/modules-load.d/*.conf || echo linuwu_sense > /etc/modules-load.d/linuwu_sense.conf

systemctl daemon-reload
systemctl enable --now predator.service predator-health.timer
sleep 4
systemctl --no-pager status predator.service | sed -n 1,8p
cat /tmp/predator-state
echo "installed - the Predator service now runs as a system service"
