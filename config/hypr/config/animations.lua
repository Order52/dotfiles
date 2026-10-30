-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Animations Configuration                 ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.config({
    animations = {
        enabled = true,
    },
})

local function bezier(name, x0, y0, x1, y1)
    hl.curve(name, { type = "bezier", points = { { x0, y0 }, { x1, y1 } } })
end

bezier("overshot",       0.13, 0.99, 0.29, 1.1)
bezier("linear",         0,    0,    1,    1)
bezier("md3_standard",   0.2,  0,    0,    1)
bezier("md3_decel",      0.05, 0.7,  0.1,  1)
bezier("md3_accel",      0.3,  0,    0.8,  0.15)
bezier("overshot_alt",   0.05, 0.9,  0.1,  1.1)
bezier("hyprnostretch",  0.05, 0.9,  0.1,  1.0)
bezier("menu_decel",     0.1,  1,    0,    1)
bezier("menu_accel",     0.38, 0.04, 1,    0.07)
bezier("cinematic",      0.1,  1.1,  0.1,  1.05)

-- From cachyos-new-rice: overshoot curve and spring curves
bezier("overshoot", 0.5, 0.9, 0.1, 1.1)
hl.curve("easy",   { type = "spring", mass = 1, stiffness = 500, dampening = 35 })
hl.curve("rubber", { type = "spring", mass = 1, stiffness = 200, dampening = 15 })

-- Animation configs - balanced between aesthetics and speed
hl.animation({ leaf = "windows",        enabled = true, speed = 3,   bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 3,   bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 3,   bezier = "md3_accel", style = "popin 60%" })
hl.animation({ leaf = "border",         enabled = true, speed = 5,   bezier = "default" })
hl.animation({ leaf = "fade",           enabled = true, speed = 3,   bezier = "md3_decel" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 3,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 2,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 0.5, bezier = "menu_accel" })

-- (old config set `workspaces` twice; the last one wins, which is this one)
hl.animation({ leaf = "workspaces",     enabled = true, speed = 5,   bezier = "cinematic", style = "slidefade 40%" })

-- From cachyos-new-rice: scratchpad (special workspace) slides in from the top, out to the bottom
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2, bezier = "md3_decel", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "md3_accel", style = "slide bottom" })
