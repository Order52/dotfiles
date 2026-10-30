#!/bin/bash
if hyprctl monitors | grep -q "HEADLESS"; then
  # Move focus back to the laptop to rescue active workspaces
  hyprctl dispatch 'hl.dsp.focus({ monitor = "eDP-2" })'
  sleep 0.5
  # Destroy the virtual display
  hyprctl output remove HEADLESS
  notify-send "Tablet Mode" "Virtual display destroyed."
else
  # Create the display on the left
  hyprctl output create headless HEADLESS
  hyprctl eval 'hl.monitor({ output = "HEADLESS", mode = "1920x1200@60", position = "-1920x0", scale = 1 })'

  # Force the tablet to use Workspace 11 so it doesn't steal 2 or 3
  sleep 0.5
  hyprctl dispatch 'hl.dsp.focus({ monitor = "HEADLESS" })'
  hyprctl dispatch 'hl.dsp.focus({ workspace = 10 })'
  hyprctl dispatch 'hl.dsp.focus({ monitor = "eDP-1" })'

  notify-send "Tablet Mode" "Virtual display ready on the left."
fi
