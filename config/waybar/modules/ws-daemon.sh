#!/usr/bin/env bash
# Workspace state daemon for waybar (Lua-config compatible).
# Waybar 0.15's built-in hyprland/workspaces module sends legacy "dispatch workspace N"
# commands that a Lua Hyprland rejects, so workspaces are drawn by custom/wsN modules
# (modules/workspace.sh) fed by this daemon. It listens to Hyprland's event socket,
# rewrites a small state file, and pokes waybar (SIGRTMIN+11) to redraw.

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-workspaces.json"
SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

update() {
    local ws mon
    ws=$(hyprctl -j workspaces 2>/dev/null) || return
    mon=$(hyprctl -j monitors 2>/dev/null) || return
    jq -n --argjson ws "$ws" --argjson mon "$mon" '
        ($mon | map(.activeWorkspace.id)) as $active
        | [ $ws[] | select(.id > 0)
            | {id, windows, active: (.id as $i | $active | index($i) != null)} ]' \
        > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
    pkill -RTMIN+11 -x waybar
}

update
[ -S "$SOCK" ] || { echo "ws-daemon: no Hyprland event socket at $SOCK" >&2; exit 1; }

socat -U - "UNIX-CONNECT:$SOCK" | while read -r line; do
    case "$line" in
        workspace*|focusedmon*|createworkspace*|destroyworkspace*|openwindow*|closewindow*|movewindow*|moveworkspace*)
            # coalesce bursts of events into one update
            while read -r -t 0.05 _; do :; done
            update ;;
    esac
done
