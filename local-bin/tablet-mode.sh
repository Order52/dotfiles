#!/bin/bash

# Detect current Desktop Environment
DESKTOP=$XDG_CURRENT_DESKTOP

if [[ "$DESKTOP" == *"Hyprland"* ]]; then
  # --- HYPRLAND LOGIC ---
  if hyprctl monitors | grep -q "HEADLESS"; then
    hyprctl output remove HEADLESS
    notify-send "Tablet Mode" "Hyprland: Virtual display destroyed."
  else
    hyprctl output create headless HEADLESS
    hyprctl keyword monitor HEADLESS,1920x1200@60,-1920x0,1
    sleep 0.5
    hyprctl dispatch focusmonitor HEADLESS
    hyprctl dispatch workspace 11
    hyprctl dispatch focusmonitor eDP-1
    notify-send "Tablet Mode" "Hyprland: Extended on the left (WS 11)."
  fi

elif [[ "$DESKTOP" == *"KDE"* ]]; then
  # --- KDE PLASMA LOGIC ---
  if pgrep -x "krfb-virtualmon" >/dev/null; then
    pkill krfb-virtualmon
    notify-send "Tablet Mode" "KDE: Virtual display destroyed."
  else
    # Spawn monitor (the & is important to keep it running in background)
    krfb-virtualmonitor --name "TABLET" --resolution 1920x1200 --password pass &
    sleep 2
    # Position it to the left of your 2560x1600 screen
    kscreen-doctor output.TABLET.enable output.TABLET.position.-1920,0
    notify-send "Tablet Mode" "KDE: Extended on the left."
  fi
else
  notify-send "Tablet Mode" "Error: Unsupported Desktop ($DESKTOP)"
fi
