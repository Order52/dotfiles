# dotfiles — Hyprland (Lua) + Noctalia on an Acer Predator Helios 16 (CachyOS)

Backup of a complete desktop and the hardware tuning for an **Acer Predator Helios 16 PH16-71**
(i7-13700HX, RTX 4060 Laptop, Intel/NVIDIA hybrid, CachyOS, Hyprland 0.57, Noctalia 5.4).

## What's in here

| Path | What |
|---|---|
| `config/hypr/` | Hyprland config in **Lua** (modular: `config/{animations,autostart,decorations,environment,input,keybinds,monitors,variables,windowrules,scrolling,noctalia}.lua`), lock screen, helper scripts |
| `config/noctalia/` | Noctalia shell config (bar, widgets, clipboard, screenshots, wallpaper, window switcher) |
| `local-share/noctalia-plugins/` | Custom Noctalia plugins: `toggles` (profile / fan / refresh rate / game mode / recorder bar buttons with popups) and `powermon` |
| `local-bin/predator-daemon.py` | The Predator brain: smart fan curve, CPU thermal governor and power limits, auto performance profile |
| `config/*` | Terminal, shell, GTK/Qt/Kvantum, fastfetch, btop, cava, rofi, swaync, waybar (retired, kept for reference), nvim, micro, ... |
| `scripts/` | Acer / RGB helper scripts |
| `system/` | System files (systemd units, pacman hooks, modprobe/tmpfiles, LACT GPU config, DKMS fix) — mirror of `/` |
| `root-scripts/` | One-shot installers run with `sudo` (sleep fix, profile permissions, daemon install, DKMS hardening, tests) |
| `packages-official.txt`, `packages-aur.txt` | Explicitly installed packages |

## Restore

```bash
git clone <this repo> ~/dotfiles && cd ~/dotfiles
./install.sh --packages --system      # --packages / --system are optional
```

Existing configs are copied to `~/dotfiles-backup-<date>` first. Paths assume the user `sloppy`; search/replace
`/home/sloppy` and `PREDATOR_USER=sloppy` for another user.

## The Predator setup (what the hardware tuning does)

* **Smart fan curve** (`predator-daemon.py`): stepped levels with hysteresis and early ramp-up; firmware Auto (0 rpm) when cool;
  fan floors by activity (idle / browsing / heavy / gaming / hot); coupled fans; battery shift.
* **Thermal governor + power limits**: CPU 80 W (65 W while gaming), clock cap in small steps above 88 °C — avoids the hard
  91-92 °C throttle. (Acer locks CPU undervolting in the BIOS, so power limits are the lever.)
* **Auto performance profile**: battery → Eco, power → Balanced, gaming/heavy → Performance (firmware only accepts Eco/Balanced on battery).
* **GPU (LACT)**: 2400 MHz cap, +200 MHz core offset (≈900 mV), +500 MHz VRAM. +350 crashed on this chip; keep the margin.
* **Reliability**: runs as a root system service from boot, watchdog + independent 30 s health timer, fans return to firmware on any
  stop, re-armed on suspend/resume and after kernel/NVIDIA/DKMS updates. `linuwu_sense` DKMS builds with the compiler the kernel was built with.
* **Sleep**: NVIDIA suspend/resume services enabled, VRAM saved to `/var/tmp`.

## Not included on purpose

Browser profiles, keyrings, game files, wallpapers and anything that could hold credentials. Secrets were scanned for before publishing.
