#!/usr/bin/env bash
# Scroll through existing workspaces (e+1 / e-1) using Lua dispatcher syntax.
case "$1" in
    up)   hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })' >/dev/null 2>&1 ;;
    down) hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })' >/dev/null 2>&1 ;;
esac
