-- Fan button for the bar: shows Smart (activity) or the manual mode, with live RPM.
-- Click / right-click: fan panel · Middle click: Smart curve
-- IPC: noctalia msg plugin sloppy/toggles:fan all set <smart|auto|quiet|balanced|performance|turbo|0-100>
local FAN     = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"
local FANMODE = noctalia.expandPath("~/.cache/predator-fan-mode")
local STATE   = "/tmp/predator-state"
local PANEL   = "sloppy/toggles:fan_panel"
local NAMES = { [0] = "AUTO", [30] = "QUIET", [50] = "BAL", [70] = "PERF", [100] = "TURBO" }
local LONG  = { [0] = "Auto", [30] = "Quiet", [50] = "Balanced", [70] = "Performance", [100] = "Turbo" }
local KEYS  = { auto = 0, quiet = 30, balanced = 50, performance = 70, turbo = 100 }
local ACT   = { idle = "Idle", browsing = "Browsing", gaming = "Gaming", heavy = "Heavy load", hot = "Hot!" }
local hwmon

local function trim(s) return s and (s:gsub("%s+", "")) or nil end
local function findHwmon()
  for i = 0, 24 do
    local base = "/sys/class/hwmon/hwmon" .. i
    if trim(noctalia.readFile(base .. "/name")) == "acer" then hwmon = base end
  end
end
local function readPct()
  local c, g = (trim(noctalia.readFile(FAN)) or ""):match("^(%d+),(%d+)$")
  if c then return tonumber(c), tonumber(g) end
end
local function readState()
  local s = {}
  for k, v in (noctalia.readFile(STATE) or ""):gmatch("(%w+)=([^\n]*)") do s[k] = v end
  return s
end
local function rpm(f) return hwmon and tonumber(trim(noctalia.readFile(hwmon .. "/" .. f))) or nil end
local function kfmt(n) return n >= 1000 and string.format("%.1fk", n / 1000) or tostring(n) end
local function colorFor(p) if p <= 0 then return "on_surface_variant" elseif p <= 40 then return "tertiary" elseif p <= 60 then return "secondary" elseif p < 90 then return "primary" end return "error" end
local function glyphFor(p) if p <= 0 then return "propeller" elseif p <= 40 then return "leaf" elseif p <= 60 then return "wind" elseif p < 90 then return "rocket" end return "flame" end

local function setMode(m)
  noctalia.writeFile(FANMODE, m)
end

local function apply(p)
  p = math.max(0, math.min(100, math.floor(tonumber(p) or 0)))
  if p > 0 and p < 20 then p = 20 end
  setMode("manual")
  noctalia.runAsync("sh -c 'echo " .. p .. "," .. p .. " > " .. FAN .. " 2>/dev/null'")
  noctalia.runAsync("noctalia msg osd-show " .. glyphFor(p) .. " 'Fan: " .. (LONG[p] or (p .. "%")) .. "'")
end

local function smart()
  setMode("smart")
  noctalia.runAsync("noctalia msg osd-show sparkles 'Fan: Smart curve'")
end

function update()
  noctalia.setUpdateInterval(1000)
  if not hwmon then findHwmon() end
  local cpu, gpu = readPct()
  if not cpu then
    barWidget.setGlyph("propeller") barWidget.setText("N/A") barWidget.setColor("on_surface_variant")
    barWidget.setTooltip("Fan control unavailable (linuwu_sense not loaded?)")
    return
  end
  local st = readState()
  local r1, r2 = rpm("fan1_input"), rpm("fan2_input")
  local top = math.max(r1 or 0, r2 or 0)
  local isSmart = trim(noctalia.readFile(FANMODE)) ~= "manual"
  local glyph, name, col, modeText
  if isSmart then
    glyph, name = "sparkles", "SMART"
    col = st.activity == "hot" and "error" or (top > 0 and "primary" or "on_surface_variant")
    modeText = "Smart · " .. (ACT[st.activity] or "…") .. ((cpu == 0) and "  (firmware, silent when cool)" or string.format("  (CPU %d%% / GPU %d%%)", cpu, gpu))
  else
    glyph, name, col = glyphFor(cpu), NAMES[cpu] or (cpu .. "%"), colorFor(cpu)
    modeText = (LONG[cpu] or (cpu .. "%")) .. (gpu ~= cpu and string.format("  (CPU %d%% / GPU %d%%)", cpu, gpu) or "")
  end
  barWidget.setGlyph(glyph)
  barWidget.setText(top > 0 and (name .. " " .. kfmt(top)) or name)
  barWidget.setColor(col)
  barWidget.setGlyphColor(col)
  barWidget.setTooltip({
    { "Fan", modeText },
    { "Fans", (r1 or "?") .. " / " .. (r2 or "?") .. " rpm" },
    { "Temps", "CPU " .. (st.tcpu or "?") .. " °C · GPU " .. (st.tgpu or "?") .. " °C" },
    { "Load", "CPU " .. (st.cpu or "?") .. "% · GPU " .. (st.gpu or "?") .. "%" },
    { "Click", "fan menu" }, { "Middle click", "Smart curve" } })
end

function onClick() noctalia.togglePanel(PANEL) end
function onRightClick() noctalia.togglePanel(PANEL) end
function onMiddleClick() smart() update() end
function onIpc(event, payload)
  if event ~= "set" or payload == nil then return end
  local p = tostring(payload):lower()
  if p == "smart" then smart() return end
  if KEYS[p] ~= nil then apply(KEYS[p]) return end
  local n = tonumber(p:match("^(%d+)"))
  if n then apply(n) end
end

update()
