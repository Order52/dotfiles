-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                         Keybinds                            ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- NOTE: like the old config, a few keys are bound more than once on purpose
-- (e.g. Super+R, Super+Z, XF86AudioPlay) — every matching bind fires.

local d = require("config.defaults")

local mainMod = "SUPER"
local exec = hl.dsp.exec_cmd
-- noct("cmd"): run a Noctalia command (`noctalia msg cmd`)
local function noct(cmd)
    return exec("noctalia msg " .. cmd .. " >/dev/null 2>&1")
end
local focus = hl.dsp.focus
local move = hl.dsp.window.move

-- bind(keys, dispatcher_or_fn, flags, description)
local function bind(keys, action, flags, description)
    flags = flags or {}
    if description then flags.description = description end
    return hl.bind(keys, action, flags)
end

-- ── Wallpaper / tablet / panic ──────────────────────────────────
bind("SUPER + Print", noct("wallpaper-random"), nil, "Random wallpaper (Noctalia)")
bind("ALT + SUPER + V", exec("~/.config/hypr/scripts/tablet-mode.sh"))
bind("SUPER + ALT + Delete", exec("systemctl soft-reboot"))

-- ── Cursor zoom (keyboard) ──────────────────────────────────────
local function zoom_by(factor)
    return function()
        local z = tonumber((hl.get_config("cursor.zoom_factor"))) or 1
        hl.config({ ["cursor.zoom_factor"] = math.min(3.0, math.max(1.0, z * factor)) }) -- clamped 1x-3x (cachyos-new-rice)
    end
end
local function zoom_reset()
    hl.config({ ["cursor.zoom_factor"] = 1 })
end

bind(mainMod .. " + equal",       zoom_by(1.1), { repeating = true })
bind(mainMod .. " + minus",       zoom_by(0.9), { repeating = true })
bind(mainMod .. " + KP_ADD",      zoom_by(1.1), { repeating = true })
bind(mainMod .. " + KP_SUBTRACT", zoom_by(0.9), { repeating = true })

bind(mainMod .. " + SHIFT + 0",           zoom_reset, { repeating = true })
bind(mainMod .. " + SHIFT + minus",       zoom_reset, { repeating = true })
bind(mainMod .. " + SHIFT + KP_SUBTRACT", zoom_reset, { repeating = true })

-- ── Display power ───────────────────────────────────────────────
-- (dpms must not be fired directly from a bind; defer it with a timer)
bind("SUPER + XF86AudioPlay", function()
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "toggle" }))
    end, { timeout = 500, type = "oneshot" })
end)
bind("SUPER + XF86AudioPlay", exec("~/.config/hypr/scripts/toggle_display.sh"))

bind(mainMod .. " + H", exec("~/.config/hypr/scripts/show-desktop.sh"))
bind("SUPER + Z", exec("~/bin/zoomshot.sh"), nil, "desc")

-- ── Night light (Noctalia; hyprsunset was not even running) ──────
bind("CTRL + ALT + minus", noct("nightlight-force-toggle"), nil, "Night light on/off")
bind("CTRL + ALT + equal", noct("nightlight-toggle"), nil, "Night light schedule on/off")

-- ── Apps ────────────────────────────────────────────────────────
bind(mainMod .. " + R", exec("hyprctl reload"), nil, "render hypr")
bind(mainMod .. " + Return", exec(d.terminal), nil, "Opens your preferred terminal emulator (" .. d.terminal .. ")")
-- The old `$mainMod , SHIFT -> wlogout` bind used the key name "SHIFT" (a modifier, not a key)
-- and could never fire sensibly, so it is not carried over. Use a real key if you want it:
-- bind(mainMod .. " + SHIFT + End", exec("wlogout"), nil, "power menu")

bind(mainMod .. " + W", exec(d.browser), nil, "opens cachybrowser")
bind(mainMod .. " + Z", exec("zen-browser"), nil, "opens Zen Browser")
bind(mainMod .. " + R", exec("brave-origin"), nil, "opens Brave Browser")
bind(mainMod .. " + E", exec(d.filemanager), nil, "Opens your preferred filemanager (" .. d.filemanager .. ")")
bind(mainMod .. " + A", exec(d.capturing), nil, "Screen capture selection")
bind(mainMod .. " + Q", hl.dsp.window.close(), nil, "Closes (not kill) current window")
bind(mainMod .. " + SHIFT + Q", exec('loginctl terminate-user ""'), nil, "Exits Hyprland by terminating the user sessions")
bind(mainMod .. " + M", hl.dsp.window.float({ action = "toggle" }), nil, "Switches current window between floating and tiling mode")
bind(mainMod .. " + D", noct("panel-toggle launcher"), nil, "Application launcher")
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), nil, "Toggles current window fullscreen mode")
bind(mainMod .. " + Y", hl.dsp.window.pin(), nil, "Pin current window (shows on all workspaces)")
bind(mainMod .. " + ALT + J", hl.dsp.layout("togglesplit"), nil, "Toggles current window split mode")
-- $power was never defined in the old config; enable once you set `power` in defaults.lua
if d.power then
    bind(mainMod .. " + P", exec(d.power), nil, "PowerMenu")
end
bind(mainMod .. " + V", noct("panel-toggle clipboard"), nil, "Clipboard history")

-- ── Screenshots ─────────────────────────────────────────────────
bind("Print", noct("screenshot-region"), nil, "Screenshot region (Noctalia annotator)")
-- FULL screenshot with crop
-- Pin a region on screen: capture -> small always-on-top swash window, visible on every workspace.
-- (Super+Y also pins/unpins any floating window, e.g. the full annotator.)
bind(mainMod .. " + SHIFT + A",
    exec([[bash -c 'exec swash --stdin --name pinned.png < <(grimblast --freeze save area -)']],
         { float = true, pin = true, size = { "monitor_w*0.3", "monitor_h*0.3" }, move = { "monitor_w*0.66", "monitor_h*0.08" } }),
    nil, "Screenshot region pinned on screen")
bind("SUPER + SHIFT + CTRL + Print", exec("grimblast save output - | swash --stdin --name swash-fullscreen.png"), nil, "Full screen -> swash (use the crop tool)")
bind("SUPER + SHIFT + Print", noct("screenshot-fullscreen"), nil, "Screenshot full screen")

bind("SUPER + SHIFT + X", exec("~/.config/hypr/scripts/safety.sh"))

-- ── Volume / mic ────────────────────────────────────────────────
-- Right Shift was matched as SHIFT by the old config
bind("SHIFT + up",   noct("volume-up"))
bind("SHIFT + down", noct("volume-down"))
bind("CTRL + SHIFT + up",   noct("mic-volume-up"))
bind("CTRL + SHIFT + down", noct("mic-volume-down"))

-- Scrolling layout toggle
bind(mainMod .. " + K", exec("~/.config/hypr/scripts/scrolling.sh"))

-- Bluetooth
bind(mainMod .. " + B", noct("panel-toggle control-center bluetooth"), nil, "Bluetooth")

-- Mute microphone / switch audio
bind("F8", noct("mic-mute"))
bind("F5", exec("~/.config/hypr/scripts/switch_audio.sh sound"))
bind("SHIFT + F5", exec("~/.config/hypr/scripts/switch_audio.sh mic"))

bind(mainMod .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- ── Grouping windows ────────────────────────────────────────────
bind(mainMod .. " + T", hl.dsp.group.toggle(), nil, "Toggles current window group mode (ungroup all related)")
bind(mainMod .. " + Tab", hl.dsp.group.next(), nil, "Switches to the next window in the group")

-- ── Toggle gaps ─────────────────────────────────────────────────
bind(mainMod .. " + SHIFT + G", function()
    hl.config({ ["general.gaps_out"] = 5, ["general.gaps_in"] = 3 })
end, nil, "Set CachyOS default gaps")
bind(mainMod .. " + G", function()
    hl.config({ ["general.gaps_out"] = 0, ["general.gaps_in"] = 0 })
end, nil, "Remove gaps between window")

-- ── Volume control (repeating + works on lock screen) ───────────
local rl = { repeating = true, locked = true }
bind(mainMod .. " + SHIFT + equal", noct("volume-up"), rl)
bind(mainMod .. " + SHIFT + minus", noct("volume-down"), rl)
bind(mainMod .. " + SHIFT + M", noct("volume-mute"), rl)

-- ── Playback control ────────────────────────────────────────────
bind("XF86AudioPlay", noct("media toggle"), nil, "Toggles play/pause")
bind("XF86AudioNext", noct("media next"), nil, "Next track")
bind("XF86AudioPrev", noct("media previous"), nil, "Previous track")

-- ── Screen brightness ───────────────────────────────────────────
bind("XF86MonBrightnessUp",   noct("brightness-up"), rl)
bind("XF86MonBrightnessDown", noct("brightness-down"), rl)

-- ── Keyboard backlight (Acer RGB keyboard, via rgbkb) ───────────
bind("XF86KbdBrightnessUp",   exec("~/.local/bin/kbd-rgb-brightness up"),   { repeating = true, locked = true }, "Keyboard RGB brightness up")
bind("XF86KbdBrightnessDown", exec("~/.local/bin/kbd-rgb-brightness down"), { repeating = true, locked = true }, "Keyboard RGB brightness down")
bind("XF86KbdLightOnOff",     exec("~/.local/bin/kbd-rgb-brightness toggle"), { locked = true }, "Keyboard RGB backlight on/off")
-- Own keys (the hardware Fn+F11/F12 are handled by the keyboard itself): Super+Alt+F11/F12 or Up/Down, Super+Alt+K = on/off
bind("SUPER + ALT + F12",  exec("~/.local/bin/kbd-rgb-brightness up"),   { repeating = true }, "Keyboard RGB brightness up")
bind("SUPER + ALT + F11",  exec("~/.local/bin/kbd-rgb-brightness down"), { repeating = true }, "Keyboard RGB brightness down")
bind("SUPER + ALT + Up",   exec("~/.local/bin/kbd-rgb-brightness up"),   { repeating = true }, "Keyboard RGB brightness up")
bind("SUPER + ALT + Down", exec("~/.local/bin/kbd-rgb-brightness down"), { repeating = true }, "Keyboard RGB brightness down")
bind("SUPER + ALT + K",    exec("~/.local/bin/kbd-rgb-brightness toggle"), nil, "Keyboard RGB backlight on/off")
-- letter/punctuation keys cannot be swallowed by the keyboard's Fn row: Super+Alt+[ / ]  and  Super+Alt+- / =
bind("SUPER + ALT + bracketright", exec("~/.local/bin/kbd-rgb-brightness up"),   { repeating = true }, "Keyboard RGB brightness up")
bind("SUPER + ALT + bracketleft",  exec("~/.local/bin/kbd-rgb-brightness down"), { repeating = true }, "Keyboard RGB brightness down")
bind("SUPER + ALT + equal",        exec("~/.local/bin/kbd-rgb-brightness up"),   { repeating = true }, "Keyboard RGB brightness up")
bind("SUPER + ALT + minus",        exec("~/.local/bin/kbd-rgb-brightness down"), { repeating = true }, "Keyboard RGB brightness down")

-- ── Lock ────────────────────────────────────────────────────────
bind(mainMod .. " + SHIFT + X", exec("swaylock-fancy -e -K -p 10 -f Hack-Regular"), nil, "Lock the screen")
bind("SUPER + L", exec("hyprlock"))

-- ── Window actions ──────────────────────────────────────────────
-- Move window towards a direction
bind(mainMod .. " + SHIFT + left",  move({ direction = "left" }),  nil, "Move active window to the left")
bind(mainMod .. " + SHIFT + right", move({ direction = "right" }), nil, "Move active window to the right")
bind(mainMod .. " + SHIFT + up",    move({ direction = "up" }),    nil, "Move active window upwards")
bind(mainMod .. " + SHIFT + down",  move({ direction = "down" }),  nil, "Move active window downwards")
-- Move focus
bind(mainMod .. " + left",  focus({ direction = "left" }),  nil, "Move focus to the left")
bind(mainMod .. " + right", focus({ direction = "right" }), nil, "Move focus to the right")
bind(mainMod .. " + up",    focus({ direction = "up" }),    nil, "Move focus upwards")
bind(mainMod .. " + down",  focus({ direction = "down" }),  nil, "Move focus downwards")

-- Resize mode (submap)
bind(mainMod .. " + SHIFT + R", hl.dsp.submap("resize"), nil, "Activates window resizing mode")
hl.define_submap("resize", function()
    local function rs(x, y) return hl.dsp.window.resize({ x = x, y = y, relative = true }) end
    bind("right",  rs(15, 0),  nil, "Resize to the right (resizing mode)")
    bind("left",   rs(-15, 0), nil, "Resize to the left (resizing mode)")
    bind("up",     rs(0, -15), nil, "Resize upwards (resizing mode)")
    bind("down",   rs(0, 15),  nil, "Resize downwards (resizing mode)")
    bind("l",      rs(15, 0),  nil, "Resize to the right (resizing mode)")
    bind("h",      rs(-15, 0), nil, "Resize to the left (resizing mode)")
    bind("k",      rs(0, -15), nil, "Resize upwards (resizing mode)")
    bind("j",      rs(0, 15),  nil, "Resize downwards (resizing mode)")
    bind("escape", hl.dsp.submap("reset"), nil, "Ends window resizing mode")
end)

-- Quick resize with keyboard
do
    local function rs(x, y) return hl.dsp.window.resize({ x = x, y = y, relative = true }) end
    bind("ALT + SHIFT + right", rs(15, 0),  nil, "Resize to the right")
    bind("ALT + SHIFT + left",  rs(-15, 0), nil, "Resize to the left")
    bind("ALT + SHIFT + up",    rs(0, -15), nil, "Resize upwards")
    bind("ALT + SHIFT + down",  rs(0, 15),  nil, "Resize downwards")
    bind("ALT + SHIFT + l",     rs(15, 0),  nil, "Resize to the right")
    bind("ALT + SHIFT + h",     rs(-15, 0), nil, "Resize to the left")
    bind("ALT + SHIFT + k",     rs(0, -15), nil, "Resize upwards")
    bind("ALT + SHIFT + j",     rs(0, 15),  nil, "Resize downwards")
end

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })

-- Relative workspace moves
bind(mainMod .. " + SHIFT + left",  move({ workspace = "-1" }), nil, "Move window and switch to the next workspace")
bind(mainMod .. " + SHIFT + right", move({ workspace = "+1" }), nil, "Move window and switch to the previous workspace")

-- ── Workspaces: [1-9,0] ─────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    -- Switch to workspace
    bind(mainMod .. " + " .. key, focus({ workspace = i }), nil, "Switch to workspace " .. i)
    -- Move window and follow
    bind(mainMod .. " + SHIFT + " .. key, move({ workspace = i }), nil, "Move window and switch to workspace " .. i)
    -- Move window silently
    bind(mainMod .. " + CTRL + " .. key, move({ workspace = i, follow = false }), nil, "Move window silently to workspace " .. i)
end

-- Numpad workspaces
local numpad = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior", "KP_Insert" }
for i, key in ipairs(numpad) do
    bind("SUPER + " .. key, focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key, move({ workspace = i }))
end

-- Scroll through existing workspaces
bind(mainMod .. " + SHIFT + period", focus({ workspace = "e+1" }), nil, "Scroll through workspaces incrementally")
bind(mainMod .. " + SHIFT + comma",  focus({ workspace = "e-1" }), nil, "Scroll through workspaces decrementally")
bind(mainMod .. " + mouse_down", focus({ workspace = "e+1" }), nil, "Scroll through workspaces incrementally")
bind(mainMod .. " + mouse_up",   focus({ workspace = "e-1" }), nil, "Scroll through workspaces decrementally")
bind(mainMod .. " + slash", focus({ workspace = "previous" }), nil, "Switch to the previous workspace")

-- Special workspaces (scratchpads)
bind(mainMod .. " + period", move({ workspace = "special:special" }), nil, "Move active window to Special workspace")
bind(mainMod .. " + comma", hl.dsp.workspace.toggle_special("special"), nil, "Toggles the Special workspace")
bind(mainMod .. " + ALT + 1", hl.dsp.workspace.toggle_special("scratchpad"), nil, "Call special workspace scratchpad")
bind(mainMod .. " + ALT + SHIFT + 1", move({ workspace = "special:scratchpad", follow = false }), nil, "Move active window to special workspace scratchpad")

-- ── Binds settings ──────────────────────────────────────────────
hl.config({
    binds = {
        allow_workspace_cycles          = true,
        workspace_back_and_forth        = true,
        workspace_center_on             = 1,
        movefocus_cycles_fullscreen     = true,
        window_direction_monitor_fallback = true,
    },
})

-- ── Misc apps ───────────────────────────────────────────────────
bind("SUPER + X", exec("~/.config/hypr/scripts/kill-window.sh"))

-- On-screen keyboard (quickshell); ydotoold needs to be ON
bind("SUPER + SHIFT + K", exec("quickshell -p ~/.config/quickshell/On-Screen-Keyboard/osk/OnScreenKeyboard.qml"))

bind("SUPER + C", noct("panel-toggle launcher"), nil, "Calculator (type an expression in the launcher)")
bind("SUPER + S", exec("g4music"))

-- OCR
bind("SUPER + O", exec("~/.config/hypr/scripts/ocr.sh eng"))
bind("SUPER + SHIFT + O", exec("~/.config/hypr/scripts/ocr.sh ara"))

-- Color picker
bind("SUPER + P", exec("hyprpicker"))
-- App launch
bind("ALT + space", noct("panel-toggle launcher"))

-- Alt-Tab
-- Noctalia's switcher: hold Alt, Tab / Shift+Tab cycle, RELEASE Alt to switch (Esc cancels).
-- `hold` also makes a quick tap jump to the previous window.
bind("ALT + Tab", noct("window-switcher hold"), nil, "Window switcher (release Alt to switch)")

bind("ALT + KP_Insert", exec("hyprfreeze -a"))

-- Predator keys (work on lock screen)
bind("XF86AudioMute",        noct("volume-mute"), { locked = true })
bind("XF86AudioLowerVolume", noct("volume-down"),  { locked = true })
bind("XF86AudioRaiseVolume", noct("volume-up"),  { locked = true })

-- Toggle touchpad / clean lock
bind("SUPER + F10", exec("~/.config/hypr/scripts/toggle-touchpad.sh"))
bind("SUPER + ALT + L", exec("hyprlock --config ~/.config/hypr/hyprlock-clean.conf"))

-- Draw (gromit-mpx)
bind("F11", exec("gromit-mpx --undo"))
bind("SHIFT + F11", exec("gromit-mpx --redo"))
bind("ALT + F11", exec("gromit-mpx --clear"))

-- (MPD binds removed: mpd is not running; media keys go through Noctalia/playerctl above)

bind("SUPER + F9", exec("~/.config/hypr/scripts/net-toggle.sh"))
bind("SUPER + F7", noct("notification-dnd-toggle"), nil, "Do Not Disturb")
bind("SUPER + N", noct("panel-toggle control-center notifications"), nil, "Notifications")

-- Switch between windows in a floating workspace
bind("SUPER + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Emoji
-- bind("SUPER + semicolon", exec("~/.config/hypr/scripts/fuzzel-emoji.sh"))
bind("SUPER + semicolon", noct("panel-toggle launcher /emo"), nil, "Emoji picker")

-- Draw (wayscriber)
bind("SUPER + Menu", exec("wayscriber --active"))

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              Additions from cachyos-new-rice                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- (only keys that were free in this config; Noctalia-specific binds were skipped)

-- Window management
bind(mainMod .. " + ALT + space", hl.dsp.window.float({ action = "toggle" }), nil, "Toggle floating")
bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), nil, "Maximize (keep bar/gaps)")
bind(mainMod .. " + Escape", exec("hyprctl kill"), nil, "Click a window to kill it")

-- Workspaces: step through them and jump to the next empty one
bind(mainMod .. " + CTRL + Right", focus({ workspace = "e+1" }), nil, "Next workspace")
bind(mainMod .. " + CTRL + Left",  focus({ workspace = "e-1" }), nil, "Previous workspace")
bind(mainMod .. " + CTRL + Down",  focus({ workspace = "empty" }), nil, "Next empty workspace")

-- System monitor
bind("CTRL + SHIFT + Escape", exec(d.terminal .. " -e btop"), nil, "System monitor")

-- Hardware keys
bind("XF86AudioMicMute", noct("mic-mute"), { locked = true })
bind("XF86AudioPause",   noct("media toggle"), { locked = true })

-- Apps from the rice (gnome-calculator / gnome-text-editor)
bind("XF86Calculator", exec("gnome-calculator"))
bind(mainMod .. " + ALT + T", exec("gnome-text-editor --new-window"), nil, "Text editor")
