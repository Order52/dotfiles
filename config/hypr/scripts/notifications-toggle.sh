#!/bin/bash
# A script to toggle Do Not Disturb mode for swaync.

# Toggle the Do Not Disturb state
swaync-client --toggle-dnd

# Get the *new* state after toggling
STATE=$(swaync-client --get-state)

# We use a special hint to make swaync show this notification
# even if DND is enabled.
HINT="string:x-canonical-private-synchronous:swaync-dnd-toggle"

if [ "$STATE" = "dnd" ]; then
    # Notifications are now disabled (Do Not Disturb)
    notify-send "Notifications" "DISABLED (Do Not Disturb)" -i notification-disabled-symbolic -h $HINT -t 2000
else
    # Notifications are now enabled
    notify-send "Notifications" "ENABLED" -i notification-symbolic -h $HINT -t 2000
fi

