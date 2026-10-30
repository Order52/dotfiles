#!/usr/bin/env bash
# Prints waybar JSON for workspace $1. Empty text hides the button (same as the old module).
n="$1"
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-workspaces.json"
[ -r "$STATE" ] || { echo '{"text":""}'; exit 0; }
jq -c --argjson n "$n" '
    (map(select(.id == $n)) | first) as $w
    | if $w == null or ($w.active == false and $w.windows == 0) then {text: ""}
      elif $w.active then {text: ($n|tostring), class: "active"}
      else {text: ($n|tostring), class: "occupied"} end' "$STATE"
