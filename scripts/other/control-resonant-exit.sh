#!/bin/bash
# Post-exit for CONTROL Resonant: make sure no emulation layer is left running.
systemctl --user stop dualsense-xbox-bridge dualsense-haptics-game 2>/dev/null
