# Rear light and power mode over ACPI WMI (Acer Predator Helios 16 — PH16-71)

The rear light is **not a USB device**. PredatorSense (Windows) reaches it through an ACPI WMI interface, found by reverse-engineering
`AcerECLightbarController.dll` and confirmed by sending the commands and reading the state back. The same interface also carries the power mode.
`drivers/acer-rear-wmi` is a small kernel module that exposes only the verified methods; `local-bin/acer-rear` is the command-line tool on top of it.

## Interface

* WMI GUID `7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56` (class `AcerGamingFunction`, `acer-wmi`'s `WMID_GUID4`), instance 0.
* The module binds that GUID and creates `/dev/acer-rear` (group `plugdev`). Write one text command, read the reply from the same file descriptor.
  Only the commands below exist; every argument is validated, so it is not a "call any WMI method" interface.

| Command | WMI method | Meaning |
|---|---|---|
| `get_rear` | 21, input 2 | current rear state (status byte + the 16-byte layout below) |
| `get_slot` | 21, input 1 | stored static colour |
| `set_rear <32 hex>` | 20, `u8[16]` | effect, speed, brightness, colour |
| `set_color <RRGGBB>` | 6, `u64` | static colour (rear lightbar index 8, zone bit 1) |
| `get_mode` / `get_modes` | 23, input `0x0B` / `0x0A` | power mode / bitmask of supported modes (read-only here) |
| `set_mode <0\|1\|4\|5\|6>` | 22, `(mode << 8) \| 0x0B` | power mode: 0 quiet, 1 default, 4 extreme, 5 turbo, 6 eco |

### `set_rear` layout (16 bytes)

```
[0] mode   0 static · 1 breathing · 2 neon · 3 wave · 7 twinkling
[1] speed  1..5            [2] brightness 0..100 (0 = off)      [3] 0      [4] direction 1
[5..7] R G B   used by breathing and twinkling; static takes its colour from set_color; neon/wave ignore it (send 0)
[8] 0x03   [9] 0x02   [10..15] 0
```

Static: send `set_rear` with mode 0, then `set_color`. Off = mode 0 with brightness 0.
Static colour `u64` = `(1 << 40) | (0x08 << 32) | (B << 24) | (G << 16) | (R << 8)`.

## Verified on this laptop

* Reads: rear state, static slot, power mode (`0x100` = default, matches `/sys/firmware/acpi/platform_profile` = `balanced`), supported modes (`0x7300`).
* Writes accepted by the firmware with matching read-back: static, breathing, neon, wave, brightness 0 (off), and the exact current state re-sent.
* The light visibly changed with these commands once the module was loaded.

## Power modes

`acer-wmi`/`linuwu_sense` already expose them as `/sys/firmware/acpi/platform_profile` on this model (the Noctalia profile button uses it),
so `set_mode` is only a fallback. Note: the mode table above is from Windows; the sysfs profile names do not map one-to-one.

## Not done / notes from the Windows investigation

* **Keyboard "backlight off after 30 s"** is implemented in `local-bin/kbd-backlight-timeout`: a USB HID feature report on the keyboard (`04f2:0117`, interface 3, through hidraw).
  Set `30 01 <0|1> 00 00 00 00 <chk>`, query `b0 00 00 00 00 00 00 4f`, then read the report back (`b0 01 <flag> …`, hidraw's 9-byte buffer has report ID 0 in front);
  `chk = 0xFF - sum(first 7 bytes)`. On this laptop the keyboard answers an empty `b0 00 …` until the flag was written once after power-up; after that the reads matched the
  Windows notes (`… cd` for on, `… ce` for off). Write/read-back round trips verified; the actual 30 s timeout is not timed.
* **Blue light shield** is software only (Acer Quick Access loads a colour matrix + gamma LUT; no firmware command). Implemented as `local-bin/blue-light-shield`
  on top of Noctalia's night light (`nightlight.force` + `nightlight.temperature_night`): levels off / low 4500 K / medium 3800 K / high 3200 K / long hour 2800 K.
  Acer's real per-level factors could not be recovered, so those temperatures are approximations; edit `LEVELS` in the script. Bar button: `shield.luau`.
* PredatorSense's own rear OFF button probably uses `SetGamingLED` (method 2); untested. Brightness 0 is the verified off.
* `SetGamingLEDBehavior` / `SetGamingLEDColor` (methods 10 / 12) belong to the logo LED path, not the rear light. Untested.
* Windows captures: USB showed no lighting traffic at all, which is how the WMI path was found. The upstream `ph16-71-rgb` "Rear-RGB" pcapngs are OpenRGB network traffic, not USB.

## Install / rebuild

`setup/system.sh` (run by `./install.sh`) installs the module with DKMS (`/usr/src/acer-rear-wmi-1.0`, built with clang when the kernel is clang-built, as on CachyOS),
loads it at boot (`/etc/modules-load.d/acer-rear-wmi.conf`) and installs `/etc/udev/rules.d/99-acer-rear.rules`. By hand:

```bash
cd drivers/acer-rear-wmi && make                       # picks LLVM=1 automatically for a clang-built kernel
sudo insmod acer_rear_wmi.ko && sudo chown $USER /dev/acer-rear
```
