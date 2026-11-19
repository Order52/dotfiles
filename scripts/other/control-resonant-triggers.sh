#!/bin/bash
# Per-game pre-launch for CONTROL Resonant (Faugus / Lutris pre_launch): NATIVE DualSense, no emulation.
# The game talks to the real DualSense through Wine/SDL and Linux's hid-playstation driver.
# NOTE: this prefix (DisableHidraw=1) only sees the DualSense under GE-Proton10-34. The newer
# Proton-GE (GE-Proton11-12, 2026-11-13) does not enumerate it with that setting -> keep the runner on GE-Proton10-34.
# Make sure none of the earlier layers (Xbox bridge, haptics layer, ds4u) are running and grabbing the pad.
systemctl --user stop dualsense-xbox-bridge dualsense-haptics-game ds4u-daemon 2>/dev/null

sleep 5
/usr/bin/ludusavi backup --force
