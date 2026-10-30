-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Decorations Configuration               ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    decoration = {
        -- cachyos-new-rice look
        rounding         = 20,
        active_opacity   = 0.95,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1.0,

        -- ── Blur Settings ──────────────────────────────────────
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1, -- less blur (rice had 5/3; your original was 4/1)

            -- Optimization & Appearance
            new_optimizations = true,
            xray    = true,
            special = true,

            brightness        = 1.5,
            contrast          = 0.9,
            vibrancy          = 0.0,
            vibrancy_darkness = 0.0,

            -- Performance & Transparency
            ignore_opacity     = true,
            popups             = false,
            popups_ignorealpha = 0.6,
        },

        -- ── Shadow Settings ────────────────────────────────────
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 2,
            sharp        = false,
            offset       = { 0, 2 },
            color        = "rgba(0000002A)",
        },

        -- ── Dimming ────────────────────────────────────────────
        dim_inactive = true,
        dim_strength = 0.1,
        dim_special  = 0.3, -- from cachyos-new-rice (was 0)
    },
})
