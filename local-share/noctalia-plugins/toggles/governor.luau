-- CPU governor: PERF / SAVE / AUTO, read live from sysfs.
local MAP = {
  performance  = { "PERF", "rocket",      "primary" },
  powersave    = { "SAVE", "battery-eco", "tertiary" },
  schedutil    = { "AUTO", "gauge",       "on_surface_variant" },
  ondemand     = { "AUTO", "gauge",       "on_surface_variant" },
  conservative = { "CONS", "gauge",       "on_surface_variant" },
}

function update()
  noctalia.setUpdateInterval(2000)
  local raw = noctalia.readFile("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
  local gov = raw and raw:gsub("%s+", "") or "unknown"
  local m = MAP[gov] or { gov:upper():sub(1, 4), "cpu", "on_surface_variant" }
  barWidget.setGlyph(m[2])
  barWidget.setText(m[1])
  barWidget.setGlyphColor(m[3])
  barWidget.setColor(m[3])
  barWidget.setTooltip({ { "CPU governor", gov }, { "Click", "switch performance / powersave" }, { "Middle click", "reset to automatic" } })
end
update()
