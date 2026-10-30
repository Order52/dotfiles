#!/bin/bash
#   ____                                          _      
#  / ___| ******* *** ___   ___ **   **_   **| | **_ 
# | |  * / *` | '_ ` * \ / * \ '_ `  \ /  \ / `* |/ * \
# | |_| | (_| | | | | | |  __/ | | | | | (_) | (_| |  __/
#  \____|\__,_|_| |_| |_|\___|_| |_| |_|\___/ \__,_|\___|
#
# Enhanced gamemode script with Waybar integration

CACHE_FILE="$HOME/.cache/gamemode"

# Function to get current status for Waybar (plain text output like cpufreq)
get_status() {
    if [ -f "$CACHE_FILE" ]; then
        printf "󰣘   ON"
    else
        printf "󰣙   OFF"
    fi
}

# Function to enable gamemode (silent for Waybar)
enable_gamemode() {
    if [ -f "$CACHE_FILE" ]; then
        return 0
    fi
    
    hyprctl eval 'hl.config({
        ["animations.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
        ["decoration.blur.enabled"] = false,
        ["general.gaps_in"] = 0,
        ["general.gaps_out"] = 0,
        ["general.border_size"] = 1,
        ["decoration.rounding"] = 0,
    })' >/dev/null 2>&1

    touch "$CACHE_FILE"
    noctalia msg osd-show device-gamepad-2 "Gamemode ON" >/dev/null 2>&1 &
}

# Function to disable gamemode (silent for Waybar)
disable_gamemode() {
    if [ ! -f "$CACHE_FILE" ]; then
        return 0
    fi
    
    hyprctl reload >/dev/null 2>&1
    rm -f "$CACHE_FILE"
    noctalia msg osd-show device-gamepad-2 "Gamemode OFF" >/dev/null 2>&1 &
}

# Function for toggle
toggle_gamemode() {
    if [ -f "$CACHE_FILE" ]; then
        disable_gamemode
    else
        enable_gamemode
    fi
}

# Handle command line arguments
case "$1" in
    "status")
        get_status
        ;;
    "enable")
        enable_gamemode
        ;;
    "disable")
        disable_gamemode
        ;;
    "toggle")
        toggle_gamemode
        ;;
    *)
        echo "Usage: $0 {enable|disable|toggle|status}"
        exit 1
        ;;
esac
