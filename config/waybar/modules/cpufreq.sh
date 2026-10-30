#!/bin/bash
# Check if auto-cpufreq exists
AUTO_CPUFREQ_INSTALLED=$(command -v auto-cpufreq >/dev/null 2>&1 && echo "yes" || echo "no")

# Get current governor
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
else
    GOVERNOR="unknown"
fi

# Get current refresh rate from hyprctl
if command -v hyprctl >/dev/null 2>&1; then
    REFRESH_RATE=$(hyprctl monitors | grep -E '@[0-9]+\.[0-9]+' | head -1 | sed -n 's/.*@\([0-9]\+\.[0-9]\+\).*/\1/p')
    if [ -n "$REFRESH_RATE" ]; then
        # Round to nearest integer for cleaner display
        REFRESH_RATE=$(printf "%.0f" "$REFRESH_RATE")
        REFRESH_DISPLAY=" | 󰹑   ${REFRESH_RATE}Hz"
    else
        REFRESH_DISPLAY=""
    fi
else
    REFRESH_DISPLAY=""
fi

# Handle click actions
case $1 in
  toggle)
    if [ "$AUTO_CPUFREQ_INSTALLED" = "yes" ]; then
        # Use auto-cpufreq if available
        if [ "$GOVERNOR" = "powersave" ]; then
            sudo -n auto-cpufreq --force performance >/dev/null 2>&1
        else
            sudo -n auto-cpufreq --force powersave >/dev/null 2>&1
        fi
    else
        # Fallback to manual governor switching when auto-cpufreq not available
        # This lets us manually override TLP's automatic management temporarily
        if [ "$GOVERNOR" = "powersave" ]; then
            # Set to performance mode
            for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
                [ -f "$cpu" ] && echo "performance" | sudo tee "$cpu" >/dev/null 2>&1
            done
        else
            # Set to powersave mode
            for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
                [ -f "$cpu" ] && echo "powersave" | sudo tee "$cpu" >/dev/null 2>&1
            done
        fi
    fi
    # Force refresh by sleeping briefly to let changes take effect
    sleep 0.1
    ;;
  reset)
    if [ "$AUTO_CPUFREQ_INSTALLED" = "yes" ]; then
        # Reset to auto-cpufreq automatic management
        sudo -n auto-cpufreq --force reset >/dev/null 2>&1
    else
        # Reset to TLP automatic management
        # TLP automatically switches governors based on AC/BAT power status
        # We set it to 'ondemand' or 'schedutil' which are good automatic governors
        AVAILABLE_GOVERNORS=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
        
        # Choose the best automatic governor available
        if [[ "$AVAILABLE_GOVERNORS" == *"schedutil"* ]]; then
            GOV="schedutil"
        elif [[ "$AVAILABLE_GOVERNORS" == *"ondemand"* ]]; then
            GOV="ondemand"
        elif [[ "$AVAILABLE_GOVERNORS" == *"powersave"* ]]; then
            GOV="powersave"
        else
            GOV="performance"
        fi
        
        # Apply the automatic governor to all CPUs
        for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
            [ -f "$cpu" ] && echo "$GOV" | sudo tee "$cpu" >/dev/null 2>&1
        done
    fi
    # Force refresh by sleeping briefly to let changes take effect
    sleep 0.1
    ;;
esac

# Re-read governor after potential change
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
else
    GOVERNOR="unknown"
fi

# On-screen popup (only for the click actions, not for the periodic status refresh)
case "$1" in
  toggle|reset) noctalia msg osd-show cpu "CPU: $GOVERNOR" >/dev/null 2>&1 ;;
esac

# Map governor to icon + text with refresh rate
case $GOVERNOR in
    "performance")
        echo "󰾆   performance${REFRESH_DISPLAY}"
        ;;
    "powersave")
        echo "󰂏 powersave${REFRESH_DISPLAY}"
        ;;
    "ondemand")
        echo "⚖️ ondemand${REFRESH_DISPLAY}"
        ;;
    "conservative")
        echo "🐌 conservative${REFRESH_DISPLAY}"
        ;;
    "schedutil")
        echo "📊 schedutil${REFRESH_DISPLAY}"
        ;;
    "userspace")
        echo "👤 userspace${REFRESH_DISPLAY}"
        ;;
    *)
        echo "❓ $GOVERNOR${REFRESH_DISPLAY}"
        ;;
esac

# Force Waybar to refresh by exiting with success status
exit 0
