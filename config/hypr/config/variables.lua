-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Variables Configuration                  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local c = require("config.colors")

-- Layout: "dwindle" | "master" | "scrolling"
-- NOTE: scripts/scrolling.sh toggles the line below — keep its format.
local layout = "dwindle"

hl.config({
    general = {
        -- Performance Tweaks
        allow_tearing           = true,  -- Reduces input lag (requires a window rule)
        -- cachyos-new-rice: grab windows by the border/gaps to resize
        resize_on_border        = true,
        extend_border_grab_area = 0,  -- was 10 (rice); a wider grab zone overlapped the bar's bottom edge

        gaps_in     = 3,
        gaps_out    = 8,
        border_size = 2,
        col = {
            -- gradient from cachyos-new-rice (was solid cachylgreen)
            active_border   = { colors = { c.cachylgreen, c.cachydgreen }, angle = 45 },
            inactive_border = c.cachygray,   -- rice: lighter, visible inactive border
        },
        layout = layout,

        snap = { enabled = true },
    },

    group = {
        col = {
            -- group colors from cachyos-new-rice
            border_active          = c.cachylblue,
            border_inactive        = c.cachygray,
            border_locked_active   = c.cachydblue,
            border_locked_inactive = c.cachygray,
        },

        groupbar = {
            font_family = "Fira Sans",
            text_color  = c.cachydblue,
            col = {
                active          = c.cachylgreen,
                inactive        = c.cachygray,
                locked_active   = c.cachydblue,
                locked_inactive = c.cachygray,
            },
        },
    },

    misc = {
        font_family        = "Fira Sans",
        splash_font_family = "Fira Sans",
        disable_hyprland_logo = true,
        col                = { splash = c.cachylgreen },
        background_color   = c.cachydblue,

        -- Swallowing
        enable_swallow = true,
        swallow_regex  = "^(nautilus|org.kde.dolphin|nemo|thunar|btrfs-assistant.)$",

        focus_on_activate = true,

        -- Display and Power Performance
        -- vrr = 1,
        -- vfr = true,
        disable_autoreload     = true,  -- Prevent unnecessary reloads (use the reload bind)
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },

    -- From cachyos-new-rice
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    xwayland = {
        force_zero_scaling = true, -- no blurry XWayland apps; set GDK_SCALE/QT scale yourself if you scale
    },

    render = {
        direct_scanout = false, -- Bypasses compositor for fullscreen apps
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})
