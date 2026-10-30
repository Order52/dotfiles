-- Screen recorder button: live timer while recording, instant feedback on click.
--   • recording  -> red "REC 01:23" (elapsed time from the pid file's mtime = recording start)
--   • idle       -> dim icon only
-- Click is handled here (not by a config action) so the display can flip immediately instead of
-- waiting for the next poll; the actual recording logic stays in toggle-record.sh.
local SCRIPT = noctalia.expandPath("~/.config/waybar/modules/toggle-record.sh")
local PIDF   = "/tmp/wf-recording.pid"

local ticks = 0
local suppressUntil = 0   -- after a stop-click: show idle at once, even if the pid file lingers a moment
local lastRec = false

local function fmt(sec)
  if sec < 0 then sec = 0 end
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%02d:%02d", m, s)
end

-- returns recording?, start time (unix seconds)
local function state()
  local pid = noctalia.readFile(PIDF)
  if not pid then return false, nil end
  pid = pid:gsub("%s+", "")
  if pid == "" or not noctalia.fileExists("/proc/" .. pid) then return false, nil end
  local info = noctalia.fileInfo(PIDF)
  return true, info and info.mtime or nil
end

function update()
  noctalia.setUpdateInterval(250)
  ticks = ticks + 1
  local rec, start = state()
  if ticks < suppressUntil then rec = false end
  lastRec = rec

  barWidget.setGlyph("player-record")
  if rec then
    local text = "REC"
    if start then text = "REC " .. fmt(os.time() - start) end
    barWidget.setText(text)
    barWidget.setGlyphColor("error")
    barWidget.setColor("error")
    barWidget.setTooltip({ { "Screen recorder", "RECORDING " .. (start and fmt(os.time() - start) or "") }, { "Click", "stop" } })
  else
    barWidget.setText("")
    barWidget.setGlyphColor("on_surface_variant")
    barWidget.setColor("on_surface_variant")
    barWidget.setTooltip({ { "Screen recorder", "idle" }, { "Click", "select an area and start" } })
  end
end

function onClick()
  if lastRec then
    suppressUntil = ticks + 12   -- ~3 s: the pid file is removed by the script within milliseconds
    lastRec = false
    barWidget.setText("")
    barWidget.setGlyphColor("on_surface_variant")
    barWidget.setColor("on_surface_variant")
  end
  noctalia.runAsync(SCRIPT)
end
update()
