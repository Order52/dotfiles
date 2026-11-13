#!/bin/bash

# Usage:
#   ./switch_audio.sh        (Defaults to switching Audio Output)
#   ./switch_audio.sh sound (Switches Audio Output)
#   ./switch_audio.sh mic   (Switches Microphone Input)

MODE="${1:-sound}" # Default to 'sound' if no parameter is given

if [[ "$MODE" == "mic" ]]; then
  # ==========================
  #       MICROPHONE MODE
  # ==========================

  # 1. Get List of Inputs (excluding "monitors" which are just speaker loopbacks)
  mapfile -t DEVICES < <(pactl list short sources | grep -v "monitor" | awk '{print $2}')

  # 2. Get Current Default Source
  CURRENT_DEVICE=$(pactl info | grep "Default Source" | awk '{print $3}')

  TYPE_NAME="Microphone"
  COMMAND_SET_DEFAULT="set-default-source"
  COMMAND_MOVE="move-source-output"
  LIST_STREAMS="source-outputs"

else
  # ==========================
  #       SPEAKER MODE
  # ==========================
  # Headphone jack plugged in: the laptop speaker and the jack share one card profile, so let TrueSense
  # flip the profile (speakers <-> headphones <-> others).
  if command -v truesense >/dev/null && truesense audio output status 2>/dev/null | grep -q '"jack_plugged": true'; then
    truesense audio output cycle >/dev/null 2>&1 && exit 0
  fi

  # 1. Real outputs only: hardware sinks, no HDMI, no gamepad speaker, no virtual sinks
  #    (AcerUltraX DTS / Purified Voice are filters in front of a real device, not places sound ends up).
  mapfile -t DEVICES < <(pactl list short sinks | awk '$2 ~ /^(alsa|bluez)_output/ {print $2}' | grep -viE 'hdmi|dualsense|controller')

  # 2. Where sound really goes now: the default sink, or, when that's the DTS sink, the device its output feeds.
  CURRENT_DEVICE=$(pactl get-default-sink)
  if [[ ! " ${DEVICES[*]} " == *" $CURRENT_DEVICE "* ]]; then
    REAL=$(pw-link -l 2>/dev/null | awk '/^acerultrax_output:output_FL/ {getline; sub(/.*-> /, ""); sub(/:.*/, ""); print; exit}')
    [ -n "$REAL" ] && CURRENT_DEVICE=$REAL
  fi

  TYPE_NAME="Audio Output"
  COMMAND_SET_DEFAULT="set-default-sink"
  COMMAND_MOVE="move-sink-input"
  LIST_STREAMS="sink-inputs"
fi

# ==========================
#      COMMON LOGIC
# ==========================

# 3. Find Next Device (Round Robin)
NEXT_INDEX=0
FOUND_CURRENT=false

for i in "${!DEVICES[@]}"; do
  if [[ "${DEVICES[$i]}" == "$CURRENT_DEVICE" ]]; then
    NEXT_INDEX=$(((i + 1) % ${#DEVICES[@]}))
    FOUND_CURRENT=true
    break
  fi
done

# Safety: If current device wasn't found (e.g., it was the HDMI we just filtered out),
# default to the first available device in the filtered list.
if [ "$FOUND_CURRENT" = false ] && [ ${#DEVICES[@]} -gt 0 ]; then
  NEXT_INDEX=0
fi

NEW_DEVICE=${DEVICES[$NEXT_INDEX]}

# Check if we actually found a device to switch to
if [ -z "$NEW_DEVICE" ]; then
  noctalia msg osd-show alert-triangle "No valid non-HDMI devices found" >/dev/null 2>&1
  exit 1
fi

# 4. Apply the Switch
pactl $COMMAND_SET_DEFAULT "$NEW_DEVICE"

# 5. Move Active Streams (Apps currently playing/recording)
# This ensures Discord/Spotify move instantly without restart
# With the AcerUltraX DTS daemon running, it picks up the new hardware default, re-routes its output there
# and makes its own sink the default again; move the apps to whatever the default ends up being.
TARGET=$NEW_DEVICE
if [[ "$MODE" != "mic" ]] && pgrep -x acerultrax-daem >/dev/null; then
  for _ in 1 2 3 4 5 6 7 8 9 10; do sleep 0.1; [ "$(pactl get-default-sink)" = acerultrax_sink ] && break; done
  TARGET=$(pactl get-default-sink)
fi
pactl list short $LIST_STREAMS | awk '{print $1}' | while read -r id; do
  pactl $COMMAND_MOVE "$id" "$TARGET" 2>/dev/null
done

# 6. On-screen display
# Get a pretty name for the notification
if [[ "$MODE" == "mic" ]]; then
  DESC=$(pactl list sources | grep -A 10 "Name: $NEW_DEVICE" | grep "Description" | head -n 1 | cut -d: -f2 | xargs)
else
  DESC=$(pactl list sinks | grep -A 10 "Name: $NEW_DEVICE" | grep "Description" | head -n 1 | cut -d: -f2 | xargs)
fi

echo "Switched $TYPE_NAME to: $DESC"
# OSD only (Noctalia popup) — no notification
if [[ "$MODE" == "mic" ]]; then ICON="microphone"; else ICON="headphones"; fi
noctalia msg osd-show "$ICON" "$DESC" >/dev/null 2>&1
