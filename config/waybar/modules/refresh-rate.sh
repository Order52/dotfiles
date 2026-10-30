#!/bin/bash

# Dynamically find the monitor name
MONITOR_NAME=$(hyprctl monitors | grep "Monitor eDP-" | awk '{print $2}' | head -1)

# Safety check: exit if no monitor was found
if [ -z "$MONITOR_NAME" ]; then
    echo "Error: No eDP monitor found."
    exit 1
fi

# Get current refresh rate from hyprctl
get_current_refresh_rate() {
    hyprctl monitors | grep -A 1 "Monitor $MONITOR_NAME" | grep -o '@[0-9]*\.[0-9]*' | sed 's/@//' | head -1
}

# Apply a mode to the eDP monitor at runtime (Lua config; persistent defaults live in
# ~/.config/hypr/config/monitors.lua)
set_mode() {
    hyprctl eval "hl.monitor({ output = \"$MONITOR_NAME\", mode = \"2560x1600@$1\", position = \"0x0\", scale = 1 })" >/dev/null 2>&1
}

# Handle click actions
case $1 in
    toggle)
        # Get current refresh rate
        CURRENT_RATE=$(get_current_refresh_rate)
        CURRENT_RATE_INT=$(printf "%.0f" "$CURRENT_RATE")
        
        if [ "$CURRENT_RATE_INT" = "165" ] || [ "$CURRENT_RATE_INT" = "164" ]; then
            # Switch to 60Hz
            set_mode 60
            echo "🔄 Switched to 60Hz"
            noctalia msg osd-show refresh "60 Hz" >/dev/null 2>&1
        else
            # Switch to 165Hz
            set_mode 165
            echo "🔄 Switched to 165Hz"
            noctalia msg osd-show refresh "165 Hz" >/dev/null 2>&1
        fi
        ;;
    status)
        # Show current refresh rate
        CURRENT_RATE=$(get_current_refresh_rate)
        CURRENT_RATE_INT=$(printf "%.0f" "$CURRENT_RATE")
        echo "🖥️  ${CURRENT_RATE_INT}Hz"
        ;;
    *)
        # Default: show current status
        CURRENT_RATE=$(get_current_refresh_rate)
        CURRENT_RATE_INT=$(printf "%.0f" "$CURRENT_RATE")
        echo "🖥️  ${CURRENT_RATE_INT}Hz"
        ;;
esac
