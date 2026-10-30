#!/bin/bash
# System-level setup (run by install.sh via sudo):  setup/system.sh <username> <repo-dir>
# Idempotent. Installs the linuwu_sense driver (DKMS), fan/thermal service, tuning, sleep fixes and update hooks.
set -uo pipefail
U=${1:?username}; REPO=${2:?repo dir}
UID_U=$(id -u "$U")
ok()   { printf '  \033[32mok\033[0m   %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; }
step() { printf '\n--- %s\n' "$*"; }
cd "$REPO"

# ------------------------------------------------------------------ driver
step "linuwu_sense driver (Acer Predator/Nitro fan, profile and RGB control)"
SRC=/usr/src/linuwu_sense-1.0
install -d "$SRC/src"
install -m 644 drivers/linuwu_sense/Makefile drivers/linuwu_sense/dkms.conf "$SRC/"
install -m 644 drivers/linuwu_sense/src/linuwu_sense.c "$SRC/src/"
dkms status linuwu_sense/1.0 2>/dev/null | grep -q . || dkms add linuwu_sense/1.0 >/dev/null 2>&1
BUILT=0
for k in /usr/lib/modules/*/build; do
  kv=$(basename "$(dirname "$k")")
  [ -d "$k/include" ] || continue
  if dkms status linuwu_sense/1.0 -k "$kv" 2>/dev/null | grep -q installed; then ok "$kv already built"; BUILT=1; continue; fi
  if dkms install linuwu_sense/1.0 -k "$kv" >/dev/null 2>&1; then ok "built for $kv"; BUILT=1; else warn "build failed for $kv (needs headers/compiler: see make.log in /var/lib/dkms/linuwu_sense)"; fi
done
[ "$BUILT" = 1 ] || warn "driver not built for any kernel - install your kernel headers and re-run"

# the stock acer_wmi would grab the same hardware
install -m 644 system/etc/modprobe.d/blacklist-acer_wmi.conf /etc/modprobe.d/
install -m 644 system/etc/modules-load.d/linuwu_sense.conf /etc/modules-load.d/
getent group linuwu_sense >/dev/null || groupadd linuwu_sense
usermod -aG linuwu_sense "$U"
rmmod acer_wmi 2>/dev/null || true
modprobe linuwu_sense 2>/dev/null && ok "module loaded" || warn "module not loaded yet (reboot may be needed)"
install -m 644 system/etc/tmpfiles.d/linuwu_sense.conf system/etc/tmpfiles.d/acer-platform-profile.conf system/etc/tmpfiles.d/predator-tuning.conf /etc/tmpfiles.d/
install -m 644 system/etc/systemd/system/linuwu_sense.service /etc/systemd/system/
systemd-tmpfiles --create /etc/tmpfiles.d/linuwu_sense.conf /etc/tmpfiles.d/acer-platform-profile.conf /etc/tmpfiles.d/predator-tuning.conf 2>/dev/null
ok "permissions: group linuwu_sense can set fan speed, profile, CPU clocks and power limits (log out/in for the group)"

# ------------------------------------------------------------------ sleep / NVIDIA
step "Sleep and NVIDIA"
if lspci 2>/dev/null | grep -qi nvidia; then
  systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate >/dev/null 2>&1 && ok "NVIDIA suspend/resume services enabled (fixes black screen on wake)"
  install -m 644 system/etc/modprobe.d/nvidia-sleep.conf /etc/modprobe.d/ && ok "VRAM saved to /var/tmp instead of RAM"
  grep -q "NVreg_PreserveVideoMemoryAllocations=1" /proc/cmdline || warn "kernel cmdline lacks nvidia.NVreg_PreserveVideoMemoryAllocations=1 - add it to your bootloader config (see system/etc/default/limine)"
fi
install -d /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
install -m 644 system/etc/systemd/sleep.conf.d/10-sleep.conf /etc/systemd/sleep.conf.d/
install -m 644 system/etc/systemd/logind.conf.d/10-lid.conf /etc/systemd/logind.conf.d/
ok "lid / sleep settings installed"

# ------------------------------------------------------------------ fan / thermal service
step "Predator fan, thermal and profile service"
install -d -m 755 /usr/local/lib/predator
install -m 755 local-bin/predator-daemon.py /usr/local/lib/predator/predator-daemon.py
install -m 755 system/usr/local/lib/predator/health.sh /usr/local/lib/predator/health.sh
sed -i "s|sloppy|$U|g; s|/run/user/1000|/run/user/$UID_U|g" /usr/local/lib/predator/health.sh
for f in predator.service predator-health.service predator-health.timer; do install -m 644 "system/etc/systemd/system/$f" /etc/systemd/system/; done
install -d /etc/systemd/system/predator.service.d
install -m 644 system/etc/systemd/system/predator.service.d/10-never-die.conf /etc/systemd/system/predator.service.d/
sed -i "s|sloppy|$U|g" /etc/systemd/system/predator.service
install -m 755 system/usr/lib/systemd/system-sleep/predator /usr/lib/systemd/system-sleep/predator
install -d /etc/pacman.d/hooks
install -m 644 system/etc/pacman.d/hooks/predator-rearm.hook system/etc/pacman.d/hooks/predator-verify.hook /etc/pacman.d/hooks/
systemctl daemon-reload
systemctl enable --now predator.service predator-health.timer >/dev/null 2>&1 && ok "predator.service + health timer running" || warn "service not started yet (needs the driver loaded)"
# a user-level copy from an earlier setup must not fight the system one
sudo -u "$U" XDG_RUNTIME_DIR=/run/user/$UID_U systemctl --user disable --now predator.service >/dev/null 2>&1 || true

# ------------------------------------------------------------------ GPU (LACT) and CPU boost
step "GPU tuning (LACT) and CPU boost"
if command -v lact >/dev/null; then
  install -d /etc/lact
  if [ ! -s /etc/lact/config.yaml ] || ! grep -q "gpus:" /etc/lact/config.yaml; then install -m 644 system/etc/lact/config.yaml /etc/lact/config.yaml; ok "GPU profile installed (2400 MHz cap, +200 core, +500 VRAM for the RTX 4060 laptop)"
  else warn "kept your existing /etc/lact/config.yaml (repo copy: system/etc/lact/config.yaml)"; fi
  systemctl enable --now lactd >/dev/null 2>&1 && ok "lactd running"
else warn "lact not installed - GPU undervolt skipped"; fi
if command -v auto-cpufreq >/dev/null; then
  auto-cpufreq --turbo auto >/dev/null 2>&1 && ok "CPU turbo set to automatic"
  systemctl enable --now auto-cpufreq >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------ rebuild initramfs once if the nvidia modprobe option changed
step "Initramfs"
if command -v mkinitcpio >/dev/null; then mkinitcpio -P >/dev/null 2>&1 && ok "initramfs rebuilt" || warn "mkinitcpio failed"; fi

step "Summary"
systemctl is-active predator >/dev/null 2>&1 && ok "predator service active" || warn "predator service not active (reboot, then: systemctl status predator)"
echo "  Reboot recommended so the driver, permissions and NVIDIA sleep hooks all apply together."
