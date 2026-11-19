#!/bin/bash
# Faugus pre_launch for Bloodborne: ds4u profile "Bloodborne"
# (R2 heavy swing break, L2 crisp gun/parry click, lights off, no synthetic haptics).
# Bloodborne is a PS4 game and never sets adaptive triggers itself, so this profile is the whole effect.
PROFILE="Bloodborne"
if ! pgrep -f 'ds4u --daemon' >/dev/null; then
    systemctl --user start ds4u-daemon
    sleep 2
fi
ds4u --switch-profile "$PROFILE"

sleep 5
/usr/bin/ludusavi backup --force

sleep 10

dualsensectl attenuation 0 0          # full-strength rumble / trigger vibration
ds4u --switch-profile "$PROFILE"      # re-apply in case the emulator reset the controller at startup
