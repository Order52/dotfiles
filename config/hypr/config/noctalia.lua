-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Noctalia shell                        ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Noctalia is the whole shell (bar, notifications, wallpaper, launcher, clipboard, polkit, Bluetooth
-- and network agents, window switcher). It is started from autostart.lua. Its panel binds live on
-- SUPER+ALT+<key> so they never collide with the main binds in keybinds.lua.

local noct = "noctalia msg "
local function n(args) return hl.dsp.exec_cmd(noct .. args) end

hl.bind("SUPER + ALT + space",  n("panel-toggle launcher"))
hl.bind("SUPER + ALT + period", n("panel-toggle launcher /emo"))
hl.bind("SUPER + ALT + X",      n("panel-toggle control-center"))
hl.bind("SUPER + ALT + A",      n("panel-toggle control-center notifications"))
hl.bind("SUPER + ALT + V",      n("panel-toggle clipboard"))
hl.bind("SUPER + ALT + W",      n("panel-toggle wallpaper"))
hl.bind("SUPER + ALT + Z",      n("settings-toggle"))
hl.bind("SUPER + ALT + C",      n("panel-toggle session"))
hl.bind("SUPER + ALT + Tab",    n("window-switcher"))

-- Noctalia panels: blur, no Hyprland animation (they animate themselves)
hl.layer_rule({
    name  = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    no_anim = true, ignore_alpha = 0.5, blur = true, blur_popups = true,
})

hl.window_rule({
    match = { class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$" },
    float = true, size = { "monitor_w*0.70", "monitor_h*0.70" },
})
