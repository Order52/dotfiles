#!/usr/bin/env bash

conf="$HOME/.config/hypr/config/variables.lua"

# Check if the file has `local layout = "dwindle"` (ignoring exact spacing)
if grep -Eq '^[[:space:]]*local[[:space:]]+layout[[:space:]]*=[[:space:]]*"dwindle"' "$conf"; then
  # Swap dwindle for scrolling
  sed -i -E 's/^([[:space:]]*local[[:space:]]+layout[[:space:]]*=[[:space:]]*)"dwindle"/\1"scrolling"/' "$conf"
  hyprctl reload
  notify-send "Hyprland" "Layout changed: Scrolling 📜"

# Check if the file has `local layout = "scrolling"`
elif grep -Eq '^[[:space:]]*local[[:space:]]+layout[[:space:]]*=[[:space:]]*"scrolling"' "$conf"; then
  # Swap scrolling for dwindle
  sed -i -E 's/^([[:space:]]*local[[:space:]]+layout[[:space:]]*=[[:space:]]*)"scrolling"/\1"dwindle"/' "$conf"
  hyprctl reload
  notify-send "Hyprland" "Layout changed: Dwindle 🪟"

else
  notify-send "Hyprland Error" "Could not detect dwindle or scrolling layout in $conf"
fi
