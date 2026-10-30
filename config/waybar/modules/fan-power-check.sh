#!/bin/bash

PS="/sys/class/power_supply/ACAD/online"
FAN="/home/sloppy/.scripts/Acer/PredatorSense/Fan Curve/Fan_Curve.py"

if [ "$(cat "$PS")" = "1" ]; then
  python3 "$FAN" --profile balanced
else
  python3 "$FAN" --profile powersave
fi

python3 "$FAN" --daemon

