#!/bin/bash

# ============================================================
# GLOBAL MICROPHONE MUTE/UNMUTE
# This script mutes ALL input sources simultaneously.
# ============================================================

# 1. Get a list of ALL source IDs (excluding monitors to avoid muting speaker loopback)
# Use 'pactl list short sources' to get the numeric IDs
SOURCES=$(pactl list short sources | grep -v "monitor" | awk '{print $1}')

# 2. Check the current status of the DEFAULT source to decide the toggle direction
# This ensures that all mics stay in sync (all on or all off)
DEFAULT_SOURCE=$(pactl info | grep "Default Source" | awk '{print $3}')
IS_MUTED=$(pactl get-source-mute "$DEFAULT_SOURCE" | awk '{print $2}')

if [ "$IS_MUTED" = "yes" ]; then
  NEW_STATE=0 # Unmute
  MSG="Microphones ACTIVE"
  ICON="microphone-sensitivity-high-symbolic"
else
  NEW_STATE=1 # Mute
  MSG="All Microphones MUTED"
  ICON="microphone-sensitivity-muted-symbolic"
fi

# 3. Loop through every detected microphone and apply the toggle
# This hits the laptop mic, USB headsets, and Bluetooth mics at the same time
for ID in $SOURCES; do
  pactl set-source-mute "$ID" "$NEW_STATE"
done

# 4. Console feedback and Desktop Notification
echo "Action: $MSG"
if command -v notify-send >/dev/null; then
  notify-send -u normal -t 2000 -i "$ICON" "Audio Control" "$MSG"
fi
