#!/bin/bash
# A script to toggle all networking (Wi-Fi and Ethernet) using nmcli.

# Get the current state of networking
STATE=$(nmcli networking)

if [ "$STATE" = "enabled" ]; then
    # If networking is enabled, disable it
    nmcli networking off
    notify-send "Network Status" "All networking DISABLED" -i network-offline -t 500
else
    # If networking is disabled, enable it
    nmcli networking on
    notify-send "Network Status" "All networking ENABLED" -i network-wired -t 500
fi

