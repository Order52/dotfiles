-- Gamemode (animations/blur/gaps off). State = ~/.cache/gamemode exists.
function update()
  noctalia.setUpdateInterval(1000)
  local on = noctalia.fileExists(noctalia.expandPath("~/.cache/gamemode"))
  barWidget.setGlyph("device-gamepad-2")
  barWidget.setText(on and "ON" or "OFF")
  barWidget.setGlyphColor(on and "primary" or "on_surface_variant")
  barWidget.setColor(on and "primary" or "on_surface_variant")
  barWidget.setTooltip({ { "Gamemode", on and "ON  (animations, blur, gaps off)" or "OFF" }, { "Click", "toggle" } })
end
update()
