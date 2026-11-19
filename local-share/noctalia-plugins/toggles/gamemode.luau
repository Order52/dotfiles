-- Gamemode (animations/blur/gaps off). State = ~/.cache/gamemode exists.
local function isHidden(id) return noctalia.getConfig("show_" .. id) == false end
function update()
  noctalia.setUpdateInterval(1000)
  local ok = noctalia.fileExists(noctalia.expandPath("~/.config/waybar/modules/gamemode.sh"))
  barWidget.setVisible(ok and not isHidden("gamemode"))   -- hidden when the script is missing or hidden from the menu
  if not ok or isHidden("gamemode") then return end
  local on = noctalia.fileExists(noctalia.expandPath("~/.cache/gamemode"))
  barWidget.setGlyph("device-gamepad-2")
  barWidget.setText(on and "ON" or "OFF")
  barWidget.setGlyphColor(on and "primary" or "on_surface_variant")
  barWidget.setColor(on and "primary" or "on_surface_variant")
  barWidget.setTooltip({ { "Gamemode", on and "ON  (animations, blur, gaps off)" or "OFF" }, { "Click", "toggle" } })
end
update()
