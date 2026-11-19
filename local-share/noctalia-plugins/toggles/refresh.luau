-- Shows the current panel refresh rate. Click (configured in config.toml) toggles 165 <-> 60 Hz.
local function isHidden(id) return noctalia.getConfig("show_" .. id) == false end
local last = nil

-- Only shown when the laptop panel (eDP) offers more than one refresh rate and the toggle script exists. Re-checked every 30 s, so it appears once installed.
local NEEDS = [=[[ -x "$HOME/.config/waybar/modules/refresh-rate.sh" ] && [ "$(hyprctl monitors 2>/dev/null | awk "/^Monitor eDP/{f=1} f&&/availableModes/{print;exit}" | grep -oE "@[0-9]+" | sort -u | wc -l)" -ge 2 ]]=]
local supported, checkedAt = false, -1e9
local function checkSupport()
  if os.time() - checkedAt < 30 then return end
  checkedAt = os.time()
  noctalia.runAsync("sh -c '" .. NEEDS .. "'", function(r)
    supported = r ~= nil and r.exitCode == 0
    barWidget.setVisible(supported and not isHidden("refresh"))
    if supported then update() end
  end)
end

local function apply(hz)
  last = hz
  barWidget.setGlyph("refresh")
  if hz then
    barWidget.setText(hz .. "Hz")
    local high = tonumber(hz) and tonumber(hz) >= 100
    barWidget.setGlyphColor(high and "primary" or "on_surface_variant")
    barWidget.setColor(high and "primary" or "on_surface_variant")
    barWidget.setTooltip({ { "Refresh rate", hz .. " Hz" }, { "Click", "toggle 165 / 60 Hz" } })
  else
    barWidget.setText("--")
    barWidget.setTooltip("Refresh rate: unknown")
  end
end

function update()
  noctalia.setUpdateInterval(2000)
  checkSupport()
  if not supported then return end
  if isHidden("refresh") then barWidget.setVisible(false) return end
  barWidget.setVisible(true)
  noctalia.runAsync("hyprctl monitors 2>/dev/null | grep -oE '@[0-9]+' | head -1 | tr -d '@'", function(r)
    local hz = r and r.stdout and r.stdout:match("(%d+)")
    apply(hz)
  end)
end
barWidget.setVisible(false)   -- hidden until the support check passes
apply(nil)
update()
