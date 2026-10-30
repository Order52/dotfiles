-- Blue light shield (Acer Quick Access equivalent): Noctalia's night light forced on at a colour temperature, see local-bin/blue-light-shield.
-- State is read from Noctalia's own settings file. Click: next level · Scroll: warmer / cooler · Middle: off · IPC: set <0-4|off|low|medium|high|long>
local SETTINGS = noctalia.expandPath("~/.local/state/noctalia/settings.toml")
local LEVELS = { { "Off", nil }, { "Low", 4500 }, { "Medium", 3800 }, { "High", 3200 }, { "Long", 2800 } }

local function run(args)
  noctalia.runAsync("sh -c 'PATH=$HOME/.local/bin:$PATH blue-light-shield " .. args .. "'")
end

-- level (1 = off .. 5 = long hour), temperature
local function state()
  local raw = noctalia.readFile(SETTINGS) or ""
  local block = raw:match("%[nightlight%](.-)\n%[") or raw:match("%[nightlight%](.*)") or ""
  if block:match("force%s*=%s*true") then
    local temp = tonumber(block:match("temperature_night%s*=%s*(%d+)")) or 4000
    local best, dist = 2, math.huge
    for i = 2, #LEVELS do
      local d = math.abs(LEVELS[i][2] - temp)
      if d < dist then best, dist = i, d end
    end
    return best, temp
  end
  return 1, nil
end

function update()
  noctalia.setUpdateInterval(2000)
  local lvl, temp = state()
  barWidget.setGlyph(lvl == 1 and "eye" or "eye-heart")
  barWidget.setText(LEVELS[lvl][1])
  barWidget.setColor(lvl == 1 and "on_surface_variant" or "tertiary")
  barWidget.setGlyphColor(lvl == 1 and "on_surface_variant" or "tertiary")
  barWidget.setTooltip({
    { "Blue light shield", LEVELS[lvl][1] .. (temp and ("  (" .. temp .. " K)") or "") },
    { "Click", "next level" }, { "Scroll", "warmer / cooler" }, { "Middle click", "off" } })
end

function onClick() run("cycle") end
function onRightClick() run("cycle") end
function onMiddleClick() run("set off") end
function onScroll(axis, steps)
  if axis ~= "vertical" or steps == 0 then return end
  run(steps > 0 and "down" or "up")
end
function onIpc(event, payload)
  if event == "set" and payload then run("set " .. tostring(payload):gsub("[^%w]", "")) end
end
update()
