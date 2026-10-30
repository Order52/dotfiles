#!/bin/bash

# Kill screenshot tools
pkill -9 satty
pkill -9 grimblast
pkill -9 grim
pkill -9 slurp
pkill -9 okular

# Kill GPU screen recorder
pkill -9 gpu-screen-recorder

# Kill GPU screen recorder UI if running
pkill -9 gsr-ui 

# Optional: Show notification that tools were killed
notify-send "Terminated"
