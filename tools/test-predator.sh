#!/bin/bash
# Run with:  sudo bash ~/test-predator.sh      (~1 minute, reverts itself)
F=/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed
C=/sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
pid() { systemctl show -p MainPID --value predator; }
ok()  { echo "  PASS: $1"; }
bad() { echo "  FAIL: $1"; }

echo "1. kill -9 with the fan forced to 70% and a CPU cap set"
P=$(pid); echo 70,70 > $F; echo 3000000 > $C; kill -9 $P; sleep 3
[ "$(pid)" != "$P" ] && [ "$(pid)" != 0 ] && ok "restarted (new pid $(pid))" || bad "not restarted"
sleep 3; [ "$(cat $C)" != 3000000 ] && ok "CPU cap released (now $(cat $C); idle max is clamped by turbo-off)" || bad "cap still 3000000"

echo "2. freeze it (watchdog should restart within ~15-20 s)"
P=$(pid); kill -STOP $P
timeout 40 sh -c "until [ \"\$(systemctl show -p MainPID --value predator)\" != \"$P\" ]; do sleep 1; done"
sleep 4; [ "$(systemctl is-active predator)" = active ] && ok "watchdog recovered it" || bad "still down"

echo "3. stop it entirely: the independent health timer must bring it back (<=30 s)"
echo 70,70 > $F; echo 3000000 > $C; systemctl stop predator
sleep 1; [ "$(cat $F)" = "0,0" ] && ok "fans returned to firmware on stop" || bad "fan left at $(cat $F)"
timeout 45 sh -c 'until systemctl is-active --quiet predator; do sleep 2; done' && ok "health timer restarted it" || bad "not restarted"

echo "4. stale status file"
P=$(pid); kill -STOP $P; touch -d '-60 seconds' /tmp/predator-state
timeout 45 sh -c "until [ \"\$(systemctl show -p MainPID --value predator)\" != \"$P\" ]; do sleep 2; done"
sleep 3; [ "$(systemctl is-active predator)" = active ] && ok "recovered from stale state" || bad "still down"

echo "5. suspend/resume hook (simulated, no real sleep)"
P=$(pid); /usr/lib/systemd/system-sleep/predator pre suspend; /usr/lib/systemd/system-sleep/predator post suspend
sleep 4; [ "$(pid)" != "$P" ] && [ "$(systemctl is-active predator)" = active ] && ok "service re-armed after resume" || bad "not re-armed"

echo "6. module/driver present, timers, hooks"
lsmod | grep -q linuwu_sense && ok "linuwu_sense loaded" || bad "module missing"
systemctl is-active --quiet predator-health.timer && ok "health timer active" || bad "timer inactive"
[ -f /etc/pacman.d/hooks/predator-rearm.hook ] && ok "update hook installed" || bad "hook missing"
systemctl is-enabled --quiet predator && ok "enabled at boot" || bad "not enabled"
journalctl -u predator -n 3 --no-pager | tail -2
