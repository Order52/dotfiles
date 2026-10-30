-- Optional user overrides. Not loaded by default (matches the old config, where
-- `source user-config.conf` was commented out). Enable it in hyprland.lua.

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },

    misc = {
        no_focus_fallback        = true,
        disable_hyprland_urgency = true,
        enable_anr_dialog        = false,
        -- anr_missed_pings = false,
        -- vfr = true,
    },
})
