-- Port of ~/.config/waybar/modules/power_monitor.sh:
--   • on a draw: show watts;  otherwise show battery voltage
--   • tooltip: AC / battery state, power, voltage, charge
--   • click: power details window, right click: system power window

local function readstr(path)
  local raw = noctalia.readFile(path)
  if not raw then return nil end
  return (raw:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function readnum(path)
  local s = readstr(path)
  return s and tonumber(s) or nil
end

local function firstDir(prefix, count)
  for i = 0, count do
    local d = "/sys/class/power_supply/" .. prefix .. i
    if noctalia.fileExists(d) then return d end
  end
  return nil
end

local bat = nil
local ac  = nil

local function compute()
  if not bat then bat = firstDir("BAT", 3) end
  if not ac then
    ac = firstDir("AC", 3) or (noctalia.fileExists("/sys/class/power_supply/ACAD") and "/sys/class/power_supply/ACAD" or nil)
  end
  if not bat then return nil end

  local status   = readstr(bat .. "/status") or "Unknown"
  local capacity = readnum(bat .. "/capacity")
  local voltageU = readnum(bat .. "/voltage_now") or readnum(bat .. "/voltage_avg")
  local powerU   = readnum(bat .. "/power_now")
  if (not powerU or powerU == 0) then
    local cur = readnum(bat .. "/current_now")
    if cur and cur ~= 0 and voltageU and voltageU > 0 then
      powerU = (cur * voltageU) / 1000000
    end
  end
  local online = ac and readnum(ac .. "/online") == 1 or false
  return {
    status = status, capacity = capacity, online = online,
    volts  = voltageU and voltageU / 1000000 or nil,
    watts  = powerU and math.abs(powerU) / 1000000 or nil,
  }
end

function update()
  noctalia.setUpdateInterval(2000)
  local s = compute()
  if not s then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  local text
  if s.watts and s.watts >= 0.05 then
    text = string.format("%.1f W", s.watts)
  elseif s.volts then
    text = string.format("%.2f V", s.volts)
  else
    text = "N/A"
  end
  barWidget.setGlyph(s.online and "plug" or "bolt")
  barWidget.setText(text)

  local lines = {}
  lines[#lines + 1] = s.online and "AC Connected" or "On Battery"
  if s.watts and s.watts >= 0.05 then lines[#lines + 1] = string.format("Power: %.1f W", s.watts) end
  if s.volts then lines[#lines + 1] = string.format("Voltage: %.2f V", s.volts) end
  if s.capacity then lines[#lines + 1] = string.format("Battery: %d%% (%s)", s.capacity, s.status:lower()) end
  lines[#lines + 1] = "Click: power details · Right-click: system power"
  barWidget.setTooltip(table.concat(lines, "\n"))
end

local function inTerminal(script)
  noctalia.runAsync({
    "kitty", "--class", script == "power_details.sh" and "Power Details" or "System Power",
    "-e", "bash", "-c",
    "~/.config/waybar/modules/" .. script .. "; read -n1 -p 'Press any key to close…'",
  })
end

function onClick()      inTerminal("power_details.sh") end
function onRightClick() inTerminal("system_power.sh")  end
