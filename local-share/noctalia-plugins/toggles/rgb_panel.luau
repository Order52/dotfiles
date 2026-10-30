-- Keyboard RGB panel (Acer PH16-71): presets, effects, quick colors, speed, brightness, direction.
-- Every change runs `rgbkb`, which saves it (~/.config/rgbkb/config.json) so it is re-applied at login.
local CONFIG = noctalia.expandPath("~/.config/rgbkb/config.json")
local EFFECTS = {
  { "wave", "Wave", false }, { "neon", "Neon", false }, { "all", "Solid", true }, { "breathe", "Breathe", true },
  { "ripple", "Ripple", true }, { "snake", "Snake", true }, { "heartbeat", "Pulse", true }, { "snow", "Snow", true },
  { "fireball", "Fire", true }, { "stars", "Stars", true }, { "spot", "Spot", true }, { "lightning", "Bolt", true },
  { "rain", "Rain", true },
}
-- { id, label, glyph, effect, hex, speed, level }
local PRESETS = {
  { "cyber",  "Cyber",  "bolt",       "wave",      nil,      10, 0 },
  { "ocean",  "Ocean",  "droplet",    "breathe",   "0099FF", 5,  18 },
  { "lava",   "Lava",   "flame",      "fireball",  "FF3300", 7,  24 },
  { "matrix", "Matrix", "binary",     "rain",      "00FF55", 8,  20 },
  { "aurora", "Aurora", "sparkles",   "neon",      nil,      6,  18 },
  { "sunset", "Sunset", "sun",        "ripple",    "FF6A00", 5,  22 },
  { "game",   "Gaming", "device-gamepad-2", "all", "FF0000", 0,  0 },
  { "chill",  "Chill",  "moon",       "stars",     "B400FF", 4,  14 },
}
local COLORS = {
  { "Red", "FF0000" }, { "Orange", "FF6A00" }, { "Yellow", "FFD000" }, { "Green", "00FF55" }, { "Cyan", "00FFD0" },
  { "Blue", "00AAFF" }, { "Indigo", "3A3AFF" }, { "Purple", "B400FF" }, { "Pink", "FF00AA" }, { "White", "FFFFFF" },
}
local DIRS = { "→", "←", "↑", "↓", "↻", "↺" }

local st = { effect = "wave", hex = "00AAFF", speed = 10, level = 0, dir = 1, more = false }
local dragging = false        -- a slider is being dragged: don't overwrite it from the file

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

local function run(cmd)
  noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH " .. cmd .. "'")
end

local function apply()
  local cmd = "kbd-rgb-send " .. st.effect
  if hasColor(st.effect) then cmd = cmd .. " " .. st.hex end
  if st.effect ~= "all" then cmd = cmd .. " --speed " .. math.floor(st.speed) .. " --level " .. math.floor(st.level) end
  if st.effect == "wave" then cmd = cmd .. " --direction " .. st.dir end
  run(cmd)
end

local function lbl(t, size) return ui.label({ text = t, fontSize = size or 12, color = "on_surface_variant" }) end

local function renderPicker()
  panel.render(ui.column({ gap = 12, padding = 16 }, {
    ui.row({ gap = 10, align = "center" }, {
      ui.button({ glyph = "arrow-left", text = "Back", variant = "ghost", controlSize = "sm", onClick = "onMore" }),
      ui.column({ gap = 0, flexGrow = 1 }, {
        ui.label({ text = "Custom color", fontSize = 18, color = "tertiary" }),
        ui.label({ text = "#" .. st.hex .. "  ·  " .. (st.effect == "all" and "Solid" or st.effect), fontSize = 12, color = "on_surface_variant" }),
      }),
    }),
    ui.colorPicker({ value = "#" .. st.hex, swatches = { "#FF0000", "#FF6A00", "#FFD000", "#00FF55", "#00FFD0", "#00AAFF", "#3A3AFF", "#B400FF", "#FF00AA", "#FFFFFF" },
      onChange = "onPickerLive", onChangeEnd = "onPicker" }),
    ui.button({ glyph = "check", text = "Done", variant = "default", onClick = "onMore" }),
  }))
end

function render()
  if st.more and hasColor(st.effect) then return renderPicker() end
  local body = {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = "keyboard", size = 26, color = "tertiary" }),
      ui.column({ gap = 0, flexGrow = 1 }, {
        ui.label({ text = "Keyboard RGB", fontSize = 18, color = "tertiary" }),
        ui.label({ text = "Acer Predator PH16-71", fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.button({ glyph = "bulb-off", tooltip = "Backlight off", variant = "ghost", controlSize = "sm", onClick = "onOff" }),
    }),
  }

  -- presets (2 rows of 4)
  body[#body + 1] = lbl("Presets")
  local row = {}
  for i, p in ipairs(PRESETS) do
    row[#row + 1] = ui.button({ text = p[2], flexGrow = 1, controlSize = "sm", variant = "ghost", onClick = "onPreset_" .. p[1] })
    if #row == 4 then body[#body + 1] = ui.row({ gap = 4 }, row); row = {} end
  end

  -- effects (4 per row)
  body[#body + 1] = lbl("Effect")
  row = {}
  for i, e in ipairs(EFFECTS) do
    row[#row + 1] = ui.button({ text = e[2], flexGrow = 1, controlSize = "sm",
      variant = (st.effect == e[1]) and "default" or "ghost", onClick = "onEffect_" .. e[1] })
    if #row == 4 or i == #EFFECTS then body[#body + 1] = ui.row({ gap = 4 }, row); row = {} end
  end

  -- quick colors
  if hasColor(st.effect) then
    body[#body + 1] = lbl("Color  #" .. st.hex)
    local c1, c2 = {}, {}
    for i, c in ipairs(COLORS) do
      local b = ui.button({ text = c[1], flexGrow = 1, controlSize = "sm", fontSize = 11,
        variant = (st.hex == c[2]) and "default" or "ghost", onClick = "onColor_" .. i })
      if i <= 5 then c1[#c1 + 1] = b else c2[#c2 + 1] = b end
    end
    body[#body + 1] = ui.row({ gap = 4 }, c1)
    body[#body + 1] = ui.row({ gap = 4 }, c2)
    body[#body + 1] = ui.button({ glyph = "palette", text = "Custom color…", controlSize = "sm", variant = "ghost", onClick = "onMore" })
  end

  if st.effect ~= "all" then
    body[#body + 1] = lbl("Speed  " .. math.floor(st.speed) .. " / 11")
    body[#body + 1] = ui.slider({ min = 1, max = 11, step = 1, value = st.speed, controlSize = "md", onChange = "onSpeed", onDragEnd = "onSpeedEnd" })
    body[#body + 1] = lbl("Brightness  " .. math.floor(st.level) .. " / 32")
    body[#body + 1] = ui.slider({ min = 0, max = 32, step = 1, value = st.level, controlSize = "md", onChange = "onLevel", onDragEnd = "onLevelEnd" })
  end
  if st.effect == "wave" then
    local d = {}
    for i, a in ipairs(DIRS) do
      d[#d + 1] = ui.button({ text = a, flexGrow = 1, controlSize = "sm", variant = (st.dir == i) and "default" or "ghost", onClick = "onDir" .. i })
    end
    body[#body + 1] = lbl("Direction")
    body[#body + 1] = ui.row({ gap = 4 }, d)
  end

  body[#body + 1] = ui.row({ gap = 6 }, {
    ui.button({ glyph = "dice", text = "Random", flexGrow = 1, variant = "ghost", onClick = "onRandom" }),
    ui.button({ glyph = "refresh", text = "Reapply", flexGrow = 1, variant = "ghost", onClick = "onReapply" }),
  })

  panel.render(ui.column({ gap = 8, padding = 16 }, body))
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

local function preset(id)
  for _, p in ipairs(PRESETS) do
    if p[1] == id then
      st.effect, st.speed, st.level = p[4], p[6] > 0 and p[6] or st.speed, p[7]
      if p[5] then st.hex = p[5] end
      apply(); render(); return
    end
  end
end
function onPreset_cyber() preset("cyber") end
function onPreset_ocean() preset("ocean") end
function onPreset_lava() preset("lava") end
function onPreset_matrix() preset("matrix") end
function onPreset_aurora() preset("aurora") end
function onPreset_sunset() preset("sunset") end
function onPreset_game() preset("game") end
function onPreset_chill() preset("chill") end

local function color(i) st.hex = COLORS[i][2]; apply(); render() end
function onColor_1() color(1) end
function onColor_2() color(2) end
function onColor_3() color(3) end
function onColor_4() color(4) end
function onColor_5() color(5) end
function onColor_6() color(6) end
function onColor_7() color(7) end
function onColor_8() color(8) end
function onColor_9() color(9) end
function onColor_10() color(10) end
function onMore() st.more = not st.more; render() end
local function parseHex(v)
  local h = tostring(v or ""):gsub("#", ""):sub(1, 6)
  if #h == 6 and h:match("^%x+$") then return h:upper() end
end
function onPickerLive(v) local h = parseHex(v); if h then st.hex = h end end    -- keep the value, no re-render while dragging
function onPicker(v) local h = parseHex(v); if h then st.hex = h; apply() end end

function onSpeed(v) dragging = true; st.speed = tonumber(v) or st.speed; render() end
function onSpeedEnd(v) st.speed = tonumber(v) or st.speed; apply(); dragging = false end
function onLevel(v) dragging = true; st.level = tonumber(v) or st.level; render() end
function onLevelEnd(v) st.level = tonumber(v) or st.level; apply(); dragging = false end
function onDir1() st.dir = 1; apply(); render() end
function onDir2() st.dir = 2; apply(); render() end
function onDir3() st.dir = 3; apply(); render() end
function onDir4() st.dir = 4; apply(); render() end
function onDir5() st.dir = 5; apply(); render() end
function onDir6() st.dir = 6; apply(); render() end
function onRandom() run("kbd-rgb random") end
function onReapply() apply() end
function onOff() run("kbd-rgb-send all 000000") end

-- Live sync: keyboard brightness keys, the bar scroll, `kbd-rgb` and presets all change the saved config behind the panel's back,
-- so while the panel is open a bounded ticker re-reads it once a second and redraws when it changed.
local gen = 0
local function snapshot() return st.effect .. "|" .. st.hex .. "|" .. st.speed .. "|" .. st.level .. "|" .. st.dir end
function onOpen()
  load(); st.more = false; dragging = false
  gen = gen + 1
  local mine = gen
  local shown = nil
  noctalia.runStream("for i in $(seq 600); do echo; sleep 1; done", function()
    if mine ~= gen or dragging or st.more then return end
    local before = snapshot()
    load()
    if snapshot() ~= before then
      render()
    end
  end)
  render()
end
function onClose() gen = gen + 1 end
