# Keyboard RGB (Acer Predator Helios 16 — PH16-71)

The keyboard backlight is a USB HID device (`04f2:0117`, "USB-HID Gaming Keyboard"), **not** handled by the `linuwu_sense` driver
(that one is fans / profiles / battery). It is driven by **rgbkb** — a small Python tool (`third-party/rgbkb/ph16-71-rgb`) that talks to the
keyboard over USB. Everything you need is installed by `./install.sh`.

## Change it — from the Noctalia bar

The bar has a **keyboard button** (shows the current effect, e.g. "Wave"). **Click** it for the RGB panel: **8 one-click presets**
(Cyber, Ocean, Lava, Matrix, Aurora, Sunset, Gaming, Chill), all effects, **quick color buttons** (plus a full color picker on its own
screen under "Custom color…", with Back / Done), speed, brightness, wave direction, **Random / Reapply**, and a backlight-off button. Every change is applied instantly and saved. **Middle-click**
the button for a random effect, and **scroll** on it to change the keyboard brightness (0–32, with an on-screen readout). (Plugin: `local-share/noctalia-plugins/toggles/rgb.luau` + `rgb_panel.luau`.)

## Keyboard brightness keys

**Fn+F11 / Fn+F12** are handled by the keyboard's own firmware (it changes the backlight by itself and tells the computer nothing useful),
so software cannot hook them without fighting the keyboard. Use these Hyprland keys instead — they go through `kbd-rgb-brightness`,
update the saved value, the panel and show Noctalia's keyboard-brightness popup (level bar):

| Keys | Action |
|---|---|
| `Super + Alt + F12` or `Super + Alt + Up` | brightness up (step 4, range 0–32) |
| `Super + Alt + F11` or `Super + Alt + Down` | brightness down |
| `Super + Alt + K` | backlight off / back to the previous effect |
| `XF86KbdBrightnessUp/Down/LightOnOff` | the same, for keyboards that send those keys |

**The brightness follows a held key live.** `kbd-rgb-daemon` (user service `kbd-rgb-daemon.service`) keeps the keyboard's USB interface open
while you adjust, so each step takes ~20 ms and the keyboard does not reconnect; plain `rgbkb` reprograms the keyboard one command at a time
(~0.5 s each, and every command makes it reconnect on USB). After 3 s idle the daemon lets go, so `rgbkb` still works by itself.
`kbd-rgb-send <rgbkb args>` talks to the daemon (falls back to `rgbkb`); the Noctalia panel, `kbd-rgb` and the brightness keys all use it. A solid color (`all`) has no brightness setting — use any other effect.
`tools/capture-keyboard-reports.sh` shows what a key sends (needs sudo).

## Change it — from a terminal

```bash
kbd-rgb                      # interactive menu: effect, color, speed, brightness (saved, offers a start-up service)
kbd-rgb random               # random effect + color
kbd-rgb apply                # re-apply the last saved effect
kbd-rgb breathe 00FFAA --speed 6 --level 20
kbd-rgb wave --speed 10 --level 0 --direction 1
kbd-rgb all FF0000           # one solid color
kbd-rgb off                  # backlight off
kbd-rgb list                 # all effects
```

Effects: `wave`, `neon` (no color) · `all`, `breathe`, `ripple`, `snake`, `heartbeat`, `snow`, `fireball`, `stars`, `spot`, `lightning`, `rain` (take a HEX color).
`--speed` 1 (slow) – 11 (fast), `--level` brightness 0–32, `wave --direction` 1 right · 2 left · 3 up · 4 down · 5 clockwise · 6 counter-clockwise.
`rgbkb <effect> --help` shows the options of one effect.

## Where things live

| What | Where |
|---|---|
| Interactive menu | `scripts/rgb_menu.py` → `~/.scripts/rgb_menu.py` (also `third-party/rgbkb/rgb_menu.py`) |
| Random effect | `scripts/rgb_random.py` |
| Wrapper command | `local-bin/kbd-rgb` → `~/.local/bin/kbd-rgb` |
| The tool itself | `third-party/rgbkb/ph16-71-rgb` (pipx package `rgbkb`, command `rgbkb`) |
| Saved effect | `config/rgbkb/config.json` → `~/.config/rgbkb/config.json` |
| Applied at login | `config/hypr/config/autostart.lua` runs `rgbkb apply`, i.e. whatever you chose last (panel, `kbd-rgb` or the menu) |
| USB permission | `system/etc/udev/rules.d/99-rgbkb.rules` (lets your user talk to the keyboard without root) |
| Original upstream | <https://github.com/fuho/rgbkb> |

The menu can also write a systemd user service (`~/.config/systemd/user/rgbkb-startup.service`) that applies your saved effect at login.

## Optional: a keybind

Add to `config/hypr/config/keybinds.lua` (adjust to your style), for example:

```lua
bind("SUPER + ALT + K", exec("alacritty -e kbd-rgb"))       -- menu
bind("SUPER + ALT + R", exec("kbd-rgb random"))             -- random
```

## If it doesn't work

* `lsusb | grep 04f2:0117` must show the keyboard; the udev rule must be installed (`ls /etc/udev/rules.d/99-rgbkb.rules`), then `sudo udevadm control --reload && sudo udevadm trigger` and replug/reboot.
* `rgbkb apply` should print "Applied saved effect". If it says the device is missing, the USB id differs on your model — edit the rule.
