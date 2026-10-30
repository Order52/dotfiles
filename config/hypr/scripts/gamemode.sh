#!/bin/bash
#   ____                                          _      
#  / ___| __ _ _ __ ___   ___ _ __ ___   ___   __| | ___ 
# | |  _ / _` | '_ ` _ \ / _ \ '_ ` _ \ / _ \ / _` |/ _ \
# | |_| | (_| | | | | | |  __/ | | | | | (_) | (_| |  __/
#  \____|\__,_|_| |_| |_|\___|_| |_| |_|\___/ \__,_|\___|
#
#

if [ -f ~/.cache/gamemode ] ;then
    hyprctl reload
    rm ~/.cache/gamemode
    notify-send "Gamemode deactivated" "Animations and blur enabled"
else
    hyprctl eval 'hl.config({
        ["animations.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
        ["decoration.blur.enabled"] = false,
        ["general.gaps_in"] = 0,
        ["general.gaps_out"] = 0,
        ["general.border_size"] = 1,
        ["decoration.rounding"] = 0,
    })'
	touch ~/.cache/gamemode
    notify-send "Gamemode activated" "Animations and blur disabled"
fi
