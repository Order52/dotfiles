-- Keyboard RGB panel: effect, color, speed, brightness. Every change runs `rgbkb`, which saves it
-- (~/.config/rgbkb/config.json) so it is re-applied at login.
local CONFIG = noctalia.expandPath("~/.config/rgbkb/config.json")
local EFFECTS = {
  { "wave", "Wave", false }, { "neon", "Neon", false }, { "all", "Solid", true }, { "breathe", "Breathe", true },
  { "ripple", "Ripple", true }, { "snake", "Snake", true }, { "heartbeat", "Pulse", true }, { "snow", "Snow", true },
  { "fireball", "Fire", true }, { "stars", "Stars", true }, { "spot", "Spot", true }, { "lightning", "Bolt", true },
  { "rain", "Rain", true },
}
local SWATCHES = { "#FF0000", "#FF6A00", "#FFD000", "#00FF55", "#00FFD0", "#00AAFF", "#3A3AFF", "#B400FF", "#FF00AA", "#FFFFFF" }
local DIRS = { "→", "←", "↑", "↓", "↻", "↺" }

local st = { effect = "wave", hex = "00AAFF", speed = 10, level = 0, dir = 1 }
local function load()
  local raw = noctalia.readFile(CONFIG) or ""
  st.effect = raw:match('"effect"%s*:%s*"(%w+)"') or st.effect
  st.hex = raw:match('"hexcolor"%s*:%s*"(%x+)"') or st.hex
  st.speed = tonumber(raw:match('"speed"%s*:%s*([%d%.]+)')) or st.speed
  st.level = tonumber(raw:match('"level"%s*:%s*(%d+)')) or tonumber(raw:match('"brightness"%s*:%s*(%d+)')) or st.level
  st.dir = tonumber(raw:match('"direction"%s*:%s*(%d)')) or st.dir
end

local function hasColor(effect)
  for _, e in ipairs(EFFECTS) do if e[1] == effect then return e[3] end end
  return false
end

local function apply()
  local cmd = "rgbkb " .. st.effect
  if hasColor(st.effect) then cmd = cmd .. " " .. st.hex end
  if st.effect ~= "all" then cmd = cmd .. " --speed " .. math.floor(st.speed) .. " --level " .. math.floor(st.level) end
  if st.effect == "wave" then cmd = cmd .. " --direction " .. st.dir end
  noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH " .. cmd .. "'")
end

function render()
  local effRows, row = {}, {}
  for i, e in ipairs(EFFECTS) do
    row[#row + 1] = ui.button({ text = e[2], flexGrow = 1, controlSize = "sm",
      variant = (st.effect == e[1]) and "default" or "ghost", onClick = "onEffect_" .. e[1] })
    if #row == 4 or i == #EFFECTS then effRows[#effRows + 1] = ui.row({ gap = 4 }, row); row = {} end
  end

  local body = {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = "keyboard", size = 26, color = "tertiary" }),
      ui.column({ gap = 0, flexGrow = 1 }, {
        ui.label({ text = "Keyboard RGB", fontSize = 18, color = "tertiary" }),
        ui.label({ text = "Acer Predator PH16-71", fontSize = 12, color = "on_surface_variant" }),
      }),
    }),
    ui.column({ gap = 4 }, effRows),
  }
  if st.effect ~= "all" then
    body[#body + 1] = ui.label({ text = "Speed " .. math.floor(st.speed), fontSize = 12, color = "on_surface_variant" })
    body[#body + 1] = ui.slider({ min = 1, max = 11, step = 1, value = st.speed, controlSize = "md", onChange = "onSpeed", onDragEnd = "onSpeedEnd" })
    body[#body + 1] = ui.label({ text = "Brightness " .. math.floor(st.level) .. " / 32", fontSize = 12, color = "on_surface_variant" })
    body[#body + 1] = ui.slider({ min = 0, max = 32, step = 1, value = st.level, controlSize = "md", onChange = "onLevel", onDragEnd = "onLevelEnd" })
  end
  if st.effect == "wave" then
    local d = {}
    for i, a in ipairs(DIRS) do
      d[#d + 1] = ui.button({ text = a, flexGrow = 1, controlSize = "sm", variant = (st.dir == i) and "default" or "ghost", onClick = "onDir" .. i })
    end
    body[#body + 1] = ui.label({ text = "Direction", fontSize = 12, color = "on_surface_variant" })
    body[#body + 1] = ui.row({ gap = 4 }, d)
  end
  body[#body + 1] = ui.row({ gap = 6 }, {
    ui.button({ glyph = "dice", text = "Random", flexGrow = 1, variant = "ghost", onClick = "onRandom" }),
    ui.button({ glyph = "refresh", text = "Reapply", flexGrow = 1, variant = "ghost", onClick = "onReapply" }),
    ui.button({ glyph = "bulb-off", text = "Off", flexGrow = 1, variant = "ghost", onClick = "onOff" }),
  })
  if hasColor(st.effect) then
    body[#body + 1] = ui.label({ text = "Color", fontSize = 12, color = "on_surface_variant" })
    body[#body + 1] = ui.colorPicker({ value = "#" .. st.hex, swatches = SWATCHES, onChangeEnd = "onColor" })
  end
  panel.render(ui.column({ gap = 10, padding = 16 }, body))
end

local function pick(effect) st.effect = effect; apply(); render() end
function onEffect_wave() pick("wave") end
function onEffect_neon() pick("neon") end
function onEffect_all() pick("all") end
function onEffect_breathe() pick("breathe") end
function onEffect_ripple() pick("ripple") end
function onEffect_snake() pick("snake") end
function onEffect_heartbeat() pick("heartbeat") end
function onEffect_snow() pick("snow") end
function onEffect_fireball() pick("fireball") end
function onEffect_stars() pick("stars") end
function onEffect_spot() pick("spot") end
function onEffect_lightning() pick("lightning") end
function onEffect_rain() pick("rain") end

function onColor(v)
  local h = tostring(v or ""):gsub("#", ""):sub(1, 6)
  if #h == 6 then st.hex = h:upper(); apply(); render() end
end
function onSpeed(v) st.speed = tonumber(v) or st.speed; render() end
function onSpeedEnd(v) st.speed = tonumber(v) or st.speed; apply() end
function onLevel(v) st.level = tonumber(v) or st.level; render() end
function onLevelEnd(v) st.level = tonumber(v) or st.level; apply() end
function onDir1() st.dir = 1; apply(); render() end
function onDir2() st.dir = 2; apply(); render() end
function onDir3() st.dir = 3; apply(); render() end
function onDir4() st.dir = 4; apply(); render() end
function onDir5() st.dir = 5; apply(); render() end
function onDir6() st.dir = 6; apply(); render() end
function onRandom() noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH kbd-rgb random'"); render() end
function onReapply() apply() end
function onOff() noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH rgbkb all 000000'") end

function onOpen() load(); render() end
