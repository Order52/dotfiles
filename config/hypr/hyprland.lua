-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                 CachyOS Hyprland Configuration              ┃
-- ┃                       (Lua, v0.55+)                         ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Previous hyprlang config is archived in ~/.config/hypr/old_hyprland/

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                         Modules                             ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Same order as the old `source = ...` list (later modules win).
require("config.animations")
require("config.autostart")
require("config.decorations")
require("config.environment")
require("config.input")
require("config.keybinds")
require("config.monitors")
require("config.variables")
require("config.windowrules")
require("config.scrolling")
require("config.noctalia") -- opt-in Noctalia shell (disabled until you install it & set ENABLE)

-- Optional user overrides (was commented out in the old config):
-- require("config.user-config")


