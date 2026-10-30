#!/bin/env sh

TMP_FILE="$XDG_RUNTIME_DIR/hyprland-show-desktop"

CURRENT_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace | .name')

# Build one Lua chunk that moves each window silently to the given workspace
move_all() { # $1 = target workspace, remaining args = window addresses
  target="$1"; shift
  lua=""
  for address in "$@"; do
    [ -n "$address" ] || continue
    lua="$lua hl.dispatch(hl.dsp.window.move({ window = \"address:$address\", workspace = \"$target\", follow = false }));"
  done
  [ -n "$lua" ] && hyprctl eval "$lua"
}

if [ -s "$TMP_FILE-$CURRENT_WORKSPACE" ]; then
  # shellcheck disable=SC2046
  move_all "name:$CURRENT_WORKSPACE" $(cat "$TMP_FILE-$CURRENT_WORKSPACE")

  rm "$TMP_FILE-$CURRENT_WORKSPACE"
else
  ADDRESSES=$(hyprctl clients -j | jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address')

  # shellcheck disable=SC2086
  move_all "special:desktop" $ADDRESSES

  printf '%s\n' $ADDRESSES | sed -e '/^$/d' > "$TMP_FILE-$CURRENT_WORKSPACE"
fi
