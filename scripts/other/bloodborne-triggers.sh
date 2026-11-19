#!/bin/bash
# DualSense profile for Bloodborne (standalone: touches no game files and no launcher entries).
#   bloodborne-triggers.sh          apply the profile
#   bloodborne-triggers.sh off      clear trigger effects
#
# Bloodborne (PS4) never drives DualSense adaptive triggers itself, so this sets them once.
# R1 / L1 are plain digital buttons with no motor, so only R2 and L2 can be shaped.
#
#   R2 = strong (heavy) attack : long, heavy pull that builds resistance then breaks like a swing
#   L2 = firearm / parry       : short, crisp, snappy trigger break (timing-critical, so no long travel)
#
# weapon START STOP STRENGTH : wall begins at START (2-7), snaps at STOP (START+1..8), STRENGTH 1-8.

# --- tune here ---------------------------------------------------------------
R2_START=3; R2_STOP=7; R2_STRENGTH=8     # heavier = higher strength / wider START..STOP gap
L2_START=5; L2_STOP=6; L2_STRENGTH=7     # crisper = narrower gap
RUMBLE_ATTENUATION=0                     # 0 = full-strength rumble; 7 = weakest
TRIGGER_VIBRATION_ATTENUATION=0          # 0 = full-strength trigger vibration
# -----------------------------------------------------------------------------

if [ "$1" = "off" ]; then
    dualsensectl trigger both off
    /home/sloppy/.scripts/other/dualsense-lights-off.sh --now
    exit 0
fi

/home/sloppy/.scripts/other/dualsense-lights-off.sh --now   # lightbar, player LEDs, mic LED off
dualsensectl attenuation "$RUMBLE_ATTENUATION" "$TRIGGER_VIBRATION_ATTENUATION"
dualsensectl trigger right weapon "$R2_START" "$R2_STOP" "$R2_STRENGTH"
dualsensectl trigger left  weapon "$L2_START" "$L2_STOP" "$L2_STRENGTH"
