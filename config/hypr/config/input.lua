-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Input Configuration                      ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    input = {
        -- Touchpad settings
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },

        -- Keyboard layout
        kb_layout  = "us,ara",
        kb_variant = ",",
        kb_options = "grp:win_space_toggle,caps:swapescape",

        -- Mouse & General
        numlock_by_default         = true,
        follow_mouse               = 1,
        float_switch_override_focus = 2,
        repeat_delay               = 250,
        repeat_rate                = 35,
        special_fallthrough        = true,
        sensitivity                = 0.8,   -- values from -1.0 to 1.0
        accel_profile              = "flat", -- disables mouse acceleration
        resolve_binds_by_sym       = false,
    },
})

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                      Gesture Configuration                  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    gestures = {
        -- The distance (in pixels) of a swipe. Lower = shorter travel.
        workspace_swipe_distance = 150,
        -- How much of the swipe you must complete before letting go auto-completes it.
        workspace_swipe_cancel_ratio = 0.2,
        -- Lower = quick flicks register as a full workspace switch.
        workspace_swipe_min_speed_to_force = 10,
    },
})

-- 1. Workspace swipe: 4 fingers, fluid 1:1 left AND right
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- 2. Volume control: 3 fingers up/down
hl.gesture({
    fingers = 3, direction = "up",
    action = function() hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") end,
})
hl.gesture({
    fingers = 3, direction = "down",
    action = function() hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") end,
})

-- 3. Window resizing: 3 fingers left/right
hl.gesture({ fingers = 3, direction = "left",  action = "resize" })
hl.gesture({ fingers = 3, direction = "right", action = "resize" })

-- 4. Vertical workspace (optional)
-- hl.gesture({ fingers = 4, direction = "vertical", action = "workspace" })

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Visuals & Misc                        ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- (variables.lua loads later and overrides some of these, as before)

hl.config({
    general = {
        gaps_in         = 0,
        gaps_out        = 0,
        gaps_workspaces = 0,
        border_size     = 3,

        col = {
            active_border   = "rgba(000000FF)",
            inactive_border = "rgba(00000000)",
        },

        resize_on_border = true,
        no_focus_fallback = true,
        layout           = "dwindle",
        allow_tearing    = true,
    },

    misc = {
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex  = "(foot|kitty|allacritty|Alacritty)",

        disable_hyprland_logo     = true,
        force_default_wallpaper   = 0,
        allow_session_lock_restore = true,

        disable_splash_rendering  = true,
        initial_workspace_tracking = false,
    },
})
