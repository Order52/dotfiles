# dotfiles — Hyprland (Lua) + Noctalia + Acer Predator tuning

A complete, restorable desktop for an **Acer Predator Helios 16 (PH16-71)** — i7-13700HX, RTX 4060 Laptop, CachyOS — with
**one-click install**: packages, dotfiles, the `linuwu_sense` kernel driver, a smart fan/thermal service, GPU undervolt,
sleep fixes and update hooks.

![bar](docs/bar.png)

```bash
git clone https://github.com/Order52/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh --dry-run` shows everything it would do. `--no-packages`, `--user-only` (dotfiles only, no sudo) and `--yes` are available.
Existing configs are backed up to `~/dotfiles-backup-<date>` first. It is safe to run again.

## What you get

**Desktop**
* **Hyprland 0.57 in Lua** (modular: animations, autostart, decorations, environment, input, keybinds, monitors, variables,
  windowrules, scrolling, Noctalia integration), lock screen and helper scripts.
* **Noctalia as the single shell** — bar, launcher, notifications, clipboard (with images), screenshots (built-in annotator),
  wallpaper (random, incl. subfolders), Alt+Tab window switcher, OSDs. No waybar/swaync/rofi running in the background.
* **Custom Noctalia plugins** (`local-share/noctalia-plugins/toggles`): a **Predator profile** button, a **fan** button with a
  popup (smart curve / slider / presets), refresh-rate, game-mode and recorder buttons; plus a power monitor.
* Terminals (alacritty, kitty, foot, ghostty), fish/zsh/bash, GTK/Qt/Kvantum themes, fastfetch, btop, cava, nvim, micro, mpv, KDE settings.

**Hardware: Acer Predator**
* **`linuwu_sense` driver** (`drivers/`) built through DKMS for every installed kernel, with the compiler the kernel was built with
  (clang or gcc). Gives fan control, performance profiles, battery limiter, RGB.
* **Smart fan curve + thermal governor** (`local-bin/predator-daemon.py`, runs as `predator.service`)
  * stepped fan levels with hysteresis and early ramp-up, firmware Auto (0 rpm) when cool;
  * activity detection (idle / browsing / heavy / gaming / hot) from CPU load, GPU power and temperatures;
  * CPU power limit 80 W (65 W while gaming) and a clock governor that eases the CPU down before the 91–92 °C hardware throttle;
  * automatic performance profile: battery → Eco, power → Balanced, gaming / heavy → Performance.
* **GPU undervolt (LACT)**: 2400 MHz cap, +200 MHz core offset (≈ 900 mV), +500 MHz VRAM — stable here; +350 crashed, keep the margin.
* **Reliability**: system service from boot, watchdog, independent 30 s health timer, fans back to firmware on any stop,
  re-armed after suspend/resume and after kernel / NVIDIA / DKMS updates (pacman hooks), driver auto-rebuild with an on-screen warning.
* **Sleep**: NVIDIA suspend/resume services (the black-screen-on-wake fix), VRAM saved to disk instead of RAM, lid on suspend.

## Layout

| Path | Contents |
|---|---|
| `install.sh` | the one-click installer |
| `setup/system.sh` | root part (driver, services, tuning, hooks) — called by `install.sh` |
| `config/` | everything for `~/.config` (hypr, noctalia, waybar, terminals, themes, …) |
| `local-share/`, `local-bin/` | Noctalia plugins, the Predator daemon, small helper scripts |
| `scripts/`, `third-party/` | Acer/RGB helper scripts; vendored `predator-blue` and `rgbkb` (see credits) |
| `drivers/linuwu_sense/` | kernel driver source + DKMS config |
| `system/` | mirror of the system files that get installed under `/etc` and `/usr` (limine cmdline and LACT profile are reference copies) |
| `kde/`, `shell/` | KDE/Plasma settings, `.zshrc`/`.bashrc` |
| `packages-official.txt`, `packages-aur.txt` | explicitly installed packages; `fonts.txt` lists installed fonts |
| `tools/` | `test-predator.sh` (crash/recovery self-test), `legacy-root-scripts/` (the original step-by-step scripts) |

## After installing

* Reboot once so the driver, group permissions and NVIDIA hooks apply together.
* Wallpapers are not shipped — put images in `~/Pictures/Wallpapers`.
* Kernel command line (Limine, see `system/etc/default/limine`): `nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia_drm.modeset=1`
  (the installer warns if it is missing). Your root UUID is different — don't copy that file blindly.
* Check it: `systemctl status predator`, `cat /tmp/predator-state`, `sudo bash tools/test-predator.sh`.
* Fan mode: middle-click the fan button for Smart, or drag the slider for manual. Profile auto: middle-click the profile button.

## Notes and limits

* Tuned for this exact laptop. The GPU profile in `system/etc/lact/config.yaml` and the fan curve numbers are for the RTX 4060 /
  i7-13700HX in this chassis; on other hardware start from `--user-only` and tune yourself.
* Acer locks CPU undervolting in the BIOS of this model, so the CPU is controlled with power limits and a clock governor instead.
* Configs assume user `sloppy`; the installer rewrites `/home/sloppy` and the service user for any other account.
* Not included on purpose: browser profiles, keyrings, game files, wallpapers/photos, any tokens.

## Credits and licenses

* `drivers/linuwu_sense` — Linuwu-Sense kernel driver (GPL-2.0-or-later, derived from the Linux `acer-wmi` driver):
  <https://github.com/0x7375646F/Linuwu-Sense>
* `third-party/predator-blue` — <https://github.com/bluebottlewize/predator-blue> (own LICENSE kept in its folder)
* `third-party/rgbkb` — <https://github.com/fuho/rgbkb>
* Theme/rice parts derived from the CachyOS Hyprland rice and others keep their original headers.
