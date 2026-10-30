-- Keyboard RGB (Acer PH16-71, rgbkb). Shows the saved effect; click opens the RGB panel.
-- Middle click: random effect · IPC: noctalia msg plugin sloppy/toggles:rgb all <apply|random|off|set> [effect] [HEX]
local CONFIG = noctalia.expandPath("~/.config/rgbkb/config.json")
local PANEL  = "sloppy/toggles:rgb_panel"
local NAMES  = { wave = "Wave", neon = "Neon", all = "Solid", breathe = "Breathe", ripple = "Ripple", snake = "Snake",
                 heartbeat = "Pulse", snow = "Snow", fireball = "Fire", stars = "Stars", spot = "Spot",
                 lightning = "Bolt", rain = "Rain" }

local function run(cmd)
  noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH " .. cmd .. "'")
end

function update()
  noctalia.setUpdateInterval(3000)
  local raw = noctalia.readFile(CONFIG) or ""
  local effect = raw:match('"effect"%s*:%s*"(%w+)"')
  local hex = raw:match('"hexcolor"%s*:%s*"(%x+)"')
  barWidget.setGlyph("keyboard")
  barWidget.setText(effect and (NAMES[effect] or effect) or "RGB")
  barWidget.setColor("on_surface_variant")
  barWidget.setGlyphColor("tertiary")
  barWidget.setTooltip({
    { "Keyboard RGB", effect and (NAMES[effect] or effect) or "not set" },
    { "Color", hex and ("#" .. hex:upper()) or "-" },
    { "Click", "RGB panel" }, { "Scroll", "brightness" }, { "Middle click", "random effect" } })
end

-- scroll on the button = brightness (0-32) of the current effect
local lastScroll = 0
function onScroll(axis, steps)
  if axis ~= "vertical" or steps == 0 then return end
  local raw = noctalia.readFile(CONFIG) or ""
  local effect = raw:match('"effect"%s*:%s*"(%w+)"')
  if not effect or effect == "all" then return end
  local hex = raw:match('"hexcolor"%s*:%s*"(%x+)"')
  local speed = tonumber(raw:match('"speed"%s*:%s*([%d%.]+)')) or 10
  local level = tonumber(raw:match('"level"%s*:%s*(%d+)')) or 0
  local dir = raw:match('"direction"%s*:%s*(%d)')
  level = math.max(0, math.min(32, level + (steps > 0 and -2 or 2)))
  local cmd = "kbd-rgb-send " .. effect .. (hex and (" " .. hex) or "") .. " --speed " .. math.floor(speed) .. " --level " .. level
  if effect == "wave" and dir then cmd = cmd .. " --direction " .. dir end
  run(cmd)
  noctalia.runAsync("noctalia msg osd-show keyboard 'Keyboard brightness: " .. level .. "/32'")
end

function onClick() noctalia.togglePanel(PANEL) end
function onRightClick() noctalia.togglePanel(PANEL) end
function onMiddleClick()
  run("kbd-rgb random")
  noctalia.runAsync("noctalia msg osd-show keyboard 'Keyboard RGB: random'")
end
function onIpc(event, payload)
  if event == "apply" then run("kbd-rgb-send apply")
  elseif event == "random" then run("kbd-rgb random")
  elseif event == "off" then run("kbd-rgb-send all 000000")
  elseif event == "set" and payload then run("kbd-rgb-send " .. tostring(payload):gsub("[^%w%s#%-%.]", "")) end
end
update()
