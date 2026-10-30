#!/bin/bash

STATUS=$(hyprctl monitors -j | jq -r '.[] | select(.name=="eDP-2") | .dpmsStatus')

if [[ "$STATUS" == "true" ]]; then
    hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "eDP-2" })'
else
    hyprctl dispatch 'hl.dsp.dpms({ action = "on", monitor = "eDP-2" })'
fi

