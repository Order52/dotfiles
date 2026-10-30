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
