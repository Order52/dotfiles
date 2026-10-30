#!/bin/bash
# Run with:  sudo bash ~/harden-module.sh
# Makes the linuwu_sense fan-control kernel module survive kernel updates and reboots:
#  - builds it for the LTS kernel too (it was only built for the main kernel)
#  - the health check now rebuilds it automatically if an update left a kernel without it, and warns you on screen
set -e
SRC=/usr/src/linuwu_sense-1.0

# 1. LTS kernel (fallback boot entry) gets the module as well
for k in /usr/lib/modules/*/build; do
  kv=$(basename "$(dirname "$k")")
  [ -d "$k/include" ] || continue
  case "$kv" in *cachyos*) ;; *) continue ;; esac
  if ! dkms status linuwu_sense/1.0 -k "$kv" 2>/dev/null | grep -q installed; then
    echo "building linuwu_sense for $kv ..."
    dkms install linuwu_sense/1.0 -k "$kv" || echo "  (build failed for $kv - not fatal)"
  fi
done
dkms status

# 2. self-healing health check: missing module -> try modprobe -> dkms autoinstall for the running kernel -> OSD warning
cat > /usr/local/lib/predator/health.sh <<'EOF'
#!/bin/bash
FAN=/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed
STAMP=/run/predator-dkms-tried
osd() { runuser -u sloppy -- env HOME=/home/sloppy XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
          noctalia msg osd-show "$1" "$2" >/dev/null 2>&1; }

if [ ! -e "$FAN" ]; then
  modprobe linuwu_sense 2>/dev/null
fi
if [ ! -e "$FAN" ]; then
  # not loadable: was it never built for this kernel (update race)? rebuild once per 10 min
  if [ ! -e "$STAMP" ] || [ $(( $(date +%s) - $(stat -c %Y "$STAMP") )) -gt 600 ]; then
    touch "$STAMP"
    logger -t predator-health "linuwu_sense missing for $(uname -r): running dkms autoinstall"
    dkms autoinstall -k "$(uname -r)" >/dev/null 2>&1
    modprobe linuwu_sense 2>/dev/null
    if [ -e "$FAN" ]; then
      osd gauge "Fan driver rebuilt for the new kernel"
      systemctl restart predator.service
    else
      osd alert-triangle "Fan driver missing - fans on firmware control"
    fi
  fi
fi

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

# 3. after every package update: verify the module exists for the newest installed kernel and say so
cat > /etc/pacman.d/hooks/predator-verify.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux-cachyos*
Target = dkms

[Action]
Description = Checking the Predator fan driver was built for the new kernel...
When = PostTransaction
Exec = /bin/sh -c 'for k in /usr/lib/modules/*cachyos*/; do kv=$(basename $k); [ -d $k/build/include ] && ! dkms status linuwu_sense/1.0 -k $kv 2>/dev/null | grep -q installed && dkms install linuwu_sense/1.0 -k $kv; done; true'
EOF
systemctl start predator-health.service
echo "done"
