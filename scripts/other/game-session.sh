#!/bin/bash
# Called by Feral GameMode (~/.config/gamemode.ini [custom]) when a game starts/stops.
#   start: Hyprland game mode on (no animations/blur/gaps) + all DualSense lights off
#   end:   Hyprland game mode off (reload config)
# ~/.cache/gamemode is the same flag the manual toggle (hypr/scripts/gamemode.sh) uses.

# Make sure hyprctl finds Hyprland even if the environment is minimal.
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -n1)
    export HYPRLAND_INSTANCE_SIGNATURE
fi

LIGHTS=/home/sloppy/.scripts/other/dualsense-lights-off.sh

case "$1" in
start)
    hyprctl eval 'hl.config({
        ["animations.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
        ["decoration.blur.enabled"] = false,
        ["general.gaps_in"] = 0,
        ["general.gaps_out"] = 0,
        ["general.border_size"] = 1,
        ["decoration.rounding"] = 0,
    })' >/dev/null
    touch ~/.cache/gamemode
    "$LIGHTS" --now
    # Games often re-light the controller while they boot; turn the lights off again a few times.
    # Runs detached, because GameMode only waits a few seconds for this script.
    setsid -f bash -c "for t in 10 20 30; do sleep \$t; [ -f ~/.cache/gamemode ] && '$LIGHTS' --now; done" >/dev/null 2>&1
    notify-send -t 2500 "Game mode on" "Effects off, DualSense lights off"
    ;;
end)
    if [ -f ~/.cache/gamemode ]; then
        rm -f ~/.cache/gamemode
        hyprctl reload >/dev/null
    fi
    "$LIGHTS" --now
    notify-send -t 2500 "Game mode off" "Effects restored"
    ;;
*)
    echo "usage: $0 start|end" >&2; exit 1 ;;
esac
