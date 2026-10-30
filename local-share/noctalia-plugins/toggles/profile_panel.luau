-- Profile panel: pick the Predator performance profile.
local PROFILE = "/sys/firmware/acpi/platform_profile"
local LIST = {
  { "low-power",            "battery-eco", "Eco",         "Lowest power, cool and quiet" },
  { "quiet",                "moon",        "Quiet",       "Low fan noise" },
  { "balanced",             "scale",       "Balanced",    "Everyday default" },
  { "balanced-performance", "gauge",       "Boost",       "More power, still sensible" },
  { "performance",          "bolt",        "Performance", "Full power, loud fans" },
}
local want
local OFFFLAG = noctalia.expandPath("~/.cache/predator-auto-off")
local FAN = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"
local FANPCT = { ["low-power"]=0, quiet=30, balanced=0, ["balanced-performance"]=50, performance=70 }

local function current()
  local v = noctalia.readFile(PROFILE)
  return v and (v:gsub("%s+", "")) or nil
end

local function set(p)
  noctalia.runAsync("sh -c 'echo " .. p .. " > " .. PROFILE .. " 2>/dev/null || noctalia msg osd-show alert-triangle \"Profile: no permission (run fix-profile.sh)\"'")
  local manualFan = ((noctalia.readFile(noctalia.expandPath("~/.cache/predator-fan-mode")) or ""):gsub("%s+", "")) == "manual"
  noctalia.runAsync("sh -c 'touch " .. OFFFLAG .. (manualFan and ("; echo " .. FANPCT[p] .. "," .. FANPCT[p] .. " > " .. FAN .. " 2>/dev/null") or "") .. "'")
  want = p
  panel.close()
end

function render()
  local cur = current()
  if want ~= nil then if cur == want then want = nil else cur = want end end
  local auto = not noctalia.fileExists(OFFFLAG)
  local rows = {
    ui.button({ glyph = "refresh", text = "Auto   battery · power · load", flexGrow = 1,
      variant = auto and "default" or "ghost", onClick = "onToggleAuto" }),
    ui.label({ text = "Performance profile", color = "on_surface_variant" }),
  }
  for _, it in ipairs(LIST) do
    local on = (it[1] == cur)
    rows[#rows + 1] = ui.button({
      glyph = it[2], text = it[3] .. "   " .. it[4], flexGrow = 1,
      variant = on and "default" or "ghost",
      onClick = "onPick_" .. it[1]:gsub("-", "_"),
    })
  end
  panel.render(ui.column({ gap = 6, padding = 14 }, rows))
end

function onPick_low_power() set("low-power") end
function onPick_quiet() set("quiet") end
function onPick_balanced() set("balanced") end
function onPick_balanced_performance() set("balanced-performance") end
function onPick_performance() set("performance") end
function onToggleAuto()
  noctalia.runAsync("sh -c '" .. (noctalia.fileExists(OFFFLAG) and "rm -f " or "touch ") .. OFFFLAG .. "'")
  panel.close()
end
function onOpen() want = nil; render() end
