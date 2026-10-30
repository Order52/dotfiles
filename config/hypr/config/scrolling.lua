-- Scrolling layout options. Per-workspace use (was commented out):
-- for i = 1, 10 do hl.workspace_rule({ workspace = tostring(i), layout = "scrolling" }) end

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.7,
        focus_fit_method         = 1,
        follow_focus             = true,
        follow_min_visible       = 0.3,
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",
        direction                = "right",
    },
})
