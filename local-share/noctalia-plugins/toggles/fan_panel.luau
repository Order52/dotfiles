-- Fan panel: Smart curve (driven by the predator service), or a manual speed via slider / presets.
local FAN     = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"
local FANMODE = noctalia.expandPath("~/.cache/predator-fan-mode")
local STATE   = "/tmp/predator-state"
local PRESETS = {
  { p = 0,   label = "Auto (firmware)", glyph = "propeller" },
  { p = 30,  label = "Quiet 30%",       glyph = "leaf" },
  { p = 50,  label = "Balanced 50%",    glyph = "wind" },
  { p = 70,  label = "Performance 70%", glyph = "rocket" },
  { p = 100, label = "Turbo 100%",      glyph = "flame" },
}
local LONG = { [0] = "Auto", [30] = "Quiet", [50] = "Balanced", [70] = "Performance", [100] = "Turbo" }
local ACT  = { idle = "Idle", browsing = "Browsing", gaming = "Gaming", heavy = "Heavy", hot = "Hot!" }
local hwmon
local drag, want, wantSmart
local shownVal  -- value last given to the slider; the slider echoes it back via onChange when it changes programmatically

local function trim(s) return s and (s:gsub("%s+", "")) or nil end
local function findHwmon()
  for i = 0, 24 do
    local base = "/sys/class/hwmon/hwmon" .. i
    if trim(noctalia.readFile(base .. "/name")) == "acer" then hwmon = base end
  end
end
local function readPct()
  return tonumber((trim(noctalia.readFile(FAN)) or ""):match("^(%d+),"))
end
local function readState()
  local s = {}
  for k, v in (noctalia.readFile(STATE) or ""):gmatch("(%w+)=([^\n]*)") do s[k] = v end
  return s
end
local function smartOn()
  if wantSmart ~= nil then return wantSmart end
  return trim(noctalia.readFile(FANMODE)) ~= "manual"
end
local function rpm(f) local v = hwmon and tonumber(trim(noctalia.readFile(hwmon .. "/" .. f))); return v and (v .. " rpm") or "-" end
local function colorFor(p) if p <= 0 then return "on_surface_variant" elseif p <= 40 then return "tertiary" elseif p <= 60 then return "secondary" elseif p < 90 then return "primary" end return "error" end
local function glyphFor(p) if p <= 0 then return "propeller" elseif p <= 40 then return "leaf" elseif p <= 60 then return "wind" elseif p < 90 then return "rocket" end return "flame" end

local function setMode(m)
  noctalia.writeFile(FANMODE, m)
end

local function apply(p)
  p = math.max(0, math.min(100, math.floor(tonumber(p) or 0)))
  if p > 0 and p < 20 then p = 20 end
  setMode("manual")
  noctalia.runAsync("sh -c 'echo " .. p .. "," .. p .. " > " .. FAN .. "'")
  drag, want, wantSmart = nil, p, false
  render()
end

function render()
  if not hwmon then findHwmon() end
  local cur = readPct()
  if not cur then
    panel.render(ui.column({ gap = 8, padding = 16 }, { ui.label({ text = "Fan control unavailable", color = "error" }),
      ui.label({ text = "linuwu_sense module not loaded", color = "on_surface_variant" }) }))
    return
  end
  local st = readState()
  local smart = smartOn()
  if wantSmart ~= nil and (st.mode == "smart") == wantSmart then wantSmart = nil end
  if want ~= nil then if cur == want then want = nil else cur = want end end

  local title, sub, glyph, col, shown
  if smart and not drag then
    local c, g = (st.fan or ""):match("^(%d+),(%d+)$")
    c, g = tonumber(c), tonumber(g)
    shown = c and math.max(c, g) or 0
    title = "Smart · " .. (ACT[st.activity] or "…")
    sub = c and string.format("Curve: CPU %d%% · GPU %d%%", c, g) or "Firmware fan control (silent when cool)"
    glyph, col = "sparkles", (st.activity == "hot") and "error" or "primary"
  else
    shown = drag or cur
    title = LONG[shown] or (shown .. "%")
    sub = shown == 0 and "Firmware controlled" or (shown .. "% fan speed (manual)")
    glyph, col = glyphFor(shown), colorFor(shown)
  end

  local chips = { ui.button({ glyph = "sparkles", tooltip = "Smart curve (automatic)", flexGrow = 1,
    variant = (smart and not drag) and "default" or "ghost", onClick = "onSmart" }) }
  for _, m in ipairs(PRESETS) do
    chips[#chips + 1] = ui.button({
      glyph = m.glyph, tooltip = m.label, flexGrow = 1,
      variant = (not smart and m.p == cur and not drag) and "default" or "ghost",
      onClick = "onPreset" .. m.p,
    })
  end

  local header = {
      ui.glyph({ name = glyph, size = 28, color = col }),
      ui.column({ gap = 0, flexGrow = 1 }, {
        ui.label({ text = title, fontSize = 18, color = col }),
        ui.label({ text = sub, fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.column({ gap = 0 }, {
        ui.label({ text = "CPU " .. (st.tcpu or "?") .. " °C", fontSize = 12, color = "on_surface_variant" }),
        ui.label({ text = "GPU " .. (st.tgpu or "?") .. " °C", fontSize = 12, color = "on_surface_variant" }),
      }),
  }
  shownVal = shown
  panel.render(ui.column({ gap = 14, padding = 16 }, {
    ui.row({ gap = 10, align = "center" }, header),
    ui.slider({ min = 0, max = 100, step = 5, value = shown, controlSize = "md",
      onChange = "onSlide", onDragEnd = "onSlideEnd" }),
    ui.row({ gap = 4 }, chips),
    ui.row({ gap = 8, justify = "space_between" }, {
      ui.label({ text = "CPU fan  " .. rpm("fan1_input"), fontSize = 12, color = "on_surface_variant" }),
      ui.label({ text = "GPU fan  " .. rpm("fan2_input"), fontSize = 12, color = "on_surface_variant" }),
    }),
  }))
end

function onSlide(v)
  v = tonumber(v)
  if v == nil or (drag == nil and v == shownVal) then return end   -- programmatic echo, not the user
  drag = v; render()
end
function onSlideEnd(v)
  if drag == nil then return end                                    -- no real drag happened
  apply(tonumber(v) or drag)
end

function onSmart()
  setMode("smart")
  drag, want, wantSmart = nil, nil, true
  noctalia.runAsync("noctalia msg osd-show sparkles 'Fan: Smart curve'")
  render()
end
function onPreset0() apply(0) end
function onPreset30() apply(30) end
function onPreset50() apply(50) end
function onPreset70() apply(70) end
function onPreset100() apply(100) end

-- Panels get no update ticks, so a bounded ticker stream refreshes the open panel once a second.
local gen = 0
function onOpen()
  drag, want, wantSmart = nil, nil, nil
  gen = gen + 1
  local mine = gen
  noctalia.runStream("for i in $(seq 120); do echo; sleep 1; done", function()
    if mine == gen and not drag then render() end
  end)
  render()
end
function onClose() gen = gen + 1 end
