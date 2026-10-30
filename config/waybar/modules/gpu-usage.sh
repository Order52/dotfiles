#!/bin/bash

usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
mem=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

# Color based on GPU usage
if [ "$usage" -lt 30 ]; then
    color="#a6da95"  # Green
elif [ "$usage" -lt 70 ]; then
    color="#eed49f"  # Yellow
else
    color="#ed8796"  # Red
fi

icon=$'\uE901'

# Create JSON using cat with here document to avoid escaping issues
cat << EOF
{"text":"<span color='$color'>$icon  $mem MIB | $usage%</span>","tooltip":"GPU Usage: $usage%\nMemory Used: $mem MiB\nTemperature: $temp°C","class":"gpu"}
EOF
