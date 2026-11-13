-- Phone in the bar: battery % of the selected KDE Connect device (hidden glyph-only when offline).
-- Click: panel · Right click: ring phone · Middle click: mirror (scrcpy)
-- IPC: noctalia msg plugin sloppy/androidconnect:phone all <ring|mirror|send|browse|screenshot|record>
local CLI   = noctalia.expandPath("~/.local/bin/androidconnect")
local PANEL = "sloppy/androidconnect:panel"


-- Only shown when the androidconnect CLI and KDE Connect are installed. Re-checked every 30 s, so it appears once installed.
local NEEDS = [=[[ -x "$HOME/.local/bin/androidconnect" ] && command -v kdeconnect-cli && command -v kdeconnectd]=]
local supported, checkedAt = false, -1e9
local function checkSupport()
  if os.time() - checkedAt < 30 then return end
  checkedAt = os.time()
  noctalia.runAsync("sh -c '" .. NEEDS .. "'", function(r)
    supported = r ~= nil and r.exitCode == 0
    barWidget.setVisible(supported)
    if supported then update() end
  end)
end

local function parse(out)
  for line in (out or ""):gmatch("[^\n]+") do
    local f = {}
    for v in (line .. "|"):gmatch("([^|]*)|") do f[#f + 1] = v end
    if f[9] == "true" then
      return { id = f[1], name = f[2], online = f[3] == "true", charge = tonumber(f[4]) or -1,
               charging = f[5] == "true", notif = tonumber(f[6]) or 0, net = f[7], signal = tonumber(f[8]) or -1 }
    end
  end
end

local function battGlyph(d)
  if d.charging then return "battery-charging" end
  if d.charge >= 0 and d.charge <= 15 then return "battery-1" end
  return "device-mobile"
end

local function apply(d)
  if not d then
    barWidget.setGlyph("device-mobile-off") barWidget.setText("")
    barWidget.setColor("on_surface_variant") barWidget.setGlyphColor("on_surface_variant")
    barWidget.setTooltip("No paired phone (KDE Connect)")
    return
  end
  if not d.online then
    barWidget.setGlyph("device-mobile-off") barWidget.setText("")
    barWidget.setColor("on_surface_variant") barWidget.setGlyphColor("on_surface_variant")
    barWidget.setTooltip({ { d.name, "offline" }, { "Click", "phone panel" } })
    return
  end
  local col = (d.charge >= 0 and d.charge <= 15 and not d.charging) and "error" or "primary"
  barWidget.setGlyph(battGlyph(d))
  barWidget.setText((d.charge >= 0 and (d.charge .. "%") or "") .. (d.notif > 0 and ("  " .. d.notif) or ""))
  barWidget.setColor(col) barWidget.setGlyphColor(col)
  barWidget.setTooltip({
    { d.name, "connected" },
    { "Battery", d.charge >= 0 and (d.charge .. "%" .. (d.charging and " (charging)" or "")) or "?" },
    { "Notifications", tostring(d.notif) },
    { "Network", (d.net ~= "" and d.net or "?") .. (d.signal >= 0 and ("  " .. d.signal .. "/4") or "") },
    { "Click", "phone panel" }, { "Right click", "ring" }, { "Middle click", "mirror screen" } })
end

function update()
  noctalia.setUpdateInterval(5000)
  checkSupport()
  if not supported then return end
  noctalia.runAsync(CLI .. " status", function(r) apply(parse(r and r.stdout)) end)
end

function onClick() noctalia.togglePanel(PANEL) end
function onRightClick() noctalia.runAsync(CLI .. " ring") end
function onMiddleClick() noctalia.runAsync(CLI .. " mirror") end
local OK = { ring = 1, ping = 1, mirror = 1, send = 1, browse = 1, clip = 1, screenshot = 1, record = 1, awake = 1, wifi = 1, refresh = 1 }
function onIpc(event)
  if OK[event] then noctalia.runAsync(CLI .. " " .. event) end
end

barWidget.setVisible(false)
apply(nil)
update()
