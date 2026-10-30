#!/usr/bin/env bash
# Copy the current global IPv4 (v4) or IPv6 (v6) address to the clipboard.
# (Replaces the click actions of waybar's "network" module.)
case "$1" in
    v4) ip=$(ip -4 address show up scope global | awk '/inet /{print $2; exit}' | cut -d/ -f1) ;;
    v6) ip=$(ip -6 address show up scope global | awk '/inet6 /{print $2; exit}' | cut -d/ -f1) ;;
    *)  echo "usage: $0 v4|v6" >&2; exit 1 ;;
esac
if [ -n "$ip" ]; then
    printf '%s' "$ip" | wl-copy
    noctalia msg osd-show copy "Copied $ip" >/dev/null 2>&1
else
    noctalia msg osd-show alert-triangle "No global $1 address" >/dev/null 2>&1
fi
