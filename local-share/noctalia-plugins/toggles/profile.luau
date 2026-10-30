-- Acer Predator performance profile (ACPI platform_profile via linuwu_sense).
-- Auto switching lives in the predator service (battery -> Eco, power -> Balanced, gaming/heavy load -> Performance).
-- When the fan is in manual mode, picking a profile also sets the matching fan speed; in Smart mode the curve handles it.
-- Click: profile panel · Middle: toggle auto · IPC: set <profile> | auto <on|off>
local PROFILE = "/sys/firmware/acpi/platform_profile"
local FAN     = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"
local FANMODE = noctalia.expandPath("~/.cache/predator-fan-mode")
local OFFFLAG = noctalia.expandPath("~/.cache/predator-auto-off")
local STATE   = "/tmp/predator-state"
local PANEL   = "sloppy/toggles:profile_panel"
local INFO = {
  ["low-power"]            = { "ECO",   "battery-eco", "tertiary",           "Eco",         0  },
  ["quiet"]                = { "QUIET", "moon",        "secondary",          "Quiet",       30 },
  ["balanced"]             = { "BAL",   "scale",       "on_surface_variant", "Balanced",    0  },
  ["balanced-performance"] = { "BAL+",  "gauge",       "primary",            "Boost",       50 },
  ["performance"]          = { "PERF",  "bolt",        "error",              "Performance", 70 },
}
local ACT = { idle = "idle", browsing = "browsing", gaming = "gaming", heavy = "heavy load", hot = "hot" }

local function trim(s) return s and (s:gsub("%s+", "")) or nil end
local function current() return trim(noctalia.readFile(PROFILE)) end
local function autoOn() return not noctalia.fileExists(OFFFLAG) end

local function set(p)
  local m = INFO[p]
  if not m then return end
  noctalia.runAsync("sh -c 'touch " .. OFFFLAG .. "'")
  noctalia.runAsync("sh -c 'echo " .. p .. " > " .. PROFILE .. " 2>/dev/null || noctalia msg osd-show alert-triangle \"Profile: no permission\"'")
  if trim(noctalia.readFile(FANMODE)) == "manual" then
    noctalia.runAsync("sh -c 'echo " .. m[5] .. "," .. m[5] .. " > " .. FAN .. " 2>/dev/null'")
  end
  noctalia.runAsync("noctalia msg osd-show " .. m[2] .. " 'Profile: " .. m[4] .. "'")
end

local function setAuto(on)
  noctalia.runAsync("sh -c '" .. (on and "rm -f " or "touch ") .. OFFFLAG .. "'")
  noctalia.runAsync("noctalia msg osd-show " .. (on and "refresh" or "hand-stop") .. " 'Profile auto: " .. (on and "on" or "off") .. "'")
end

function update()
  noctalia.setUpdateInterval(2000)
  local p = current()
  local m = p and INFO[p]
  if not m then
    barWidget.setGlyph("gauge") barWidget.setText(p and p:upper():sub(1, 5) or "N/A")
    barWidget.setColor("on_surface_variant") barWidget.setGlyphColor("on_surface_variant")
    barWidget.setTooltip("Platform profile unavailable")
    return
  end
  local auto = autoOn()
  local act = (noctalia.readFile(STATE) or ""):match("activity=(%w+)")
  barWidget.setGlyph(m[2]) barWidget.setText((auto and "A·" or "") .. m[1])
  barWidget.setColor(m[3]) barWidget.setGlyphColor(m[3])
  barWidget.setTooltip({
    { "Predator profile", m[4] },
    { "Mode", auto and ("Auto · " .. (ACT[act] or "…")) or "Manual" },
    { "Click", "profile menu" }, { "Middle click", "toggle auto" } })
end

function onClick() noctalia.togglePanel(PANEL) end
function onRightClick() noctalia.togglePanel(PANEL) end
function onMiddleClick() setAuto(not autoOn()) end
function onIpc(event, payload)
  payload = payload and tostring(payload) or ""
  if event == "set" and INFO[payload] then set(payload)
  elseif event == "auto" then setAuto(payload ~= "off") end
end
update()
