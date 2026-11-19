#!/bin/bash
# Turn off every DualSense light: lightbar, player LEDs, mic LED.
# Runs once at login and again each time the controller (re)connects (see dualsense-lights-off.service).
[ "$1" = "--now" ] || sleep 1.5   # on connect, let the kernel driver finish its own default LEDs first (--now skips this)
dualsensectl lightbar off
dualsensectl player-leds 0 instant
dualsensectl microphone-led off
