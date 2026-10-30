# Local patches on top of upstream Linuwu-Sense

Upstream: https://github.com/0x7375646F/Linuwu-Sense (GPL-2.0-or-later). `src/linuwu_sense.c` already contains the patches below;
the `.patch` files are kept so they can be re-applied to a newer upstream (`patch -p1 < 0001-...patch`).

## 0001 — don't restore stale fan speeds
The driver stores the fan speeds and thermal profile per power source in `/etc/predator_state` and restores them **at module load and on every
plug/unplug**. With a userspace fan controller that means the fans jump to an old value (here CPU 60 % / GPU 40 %, or 35 % on battery) at every
boot and every time the charger is connected, until the controller overwrites it. The patch keeps restoring the thermal profile but always
returns the fans to firmware Auto (0,0), which is quiet and stops the fans completely when the laptop is cool.
