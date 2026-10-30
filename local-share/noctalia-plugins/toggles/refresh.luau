-- Shows the current panel refresh rate. Click (configured in config.toml) toggles 165 <-> 60 Hz.
local last = nil

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
  noctalia.runAsync("hyprctl monitors 2>/dev/null | grep -oE '@[0-9]+' | head -1 | tr -d '@'", function(r)
    local hz = r and r.stdout and r.stdout:match("(%d+)")
    apply(hz)
  end)
end
apply(nil)
