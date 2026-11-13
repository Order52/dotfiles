-- Phone panel: device picker, status, KDE Connect actions, and adb/scrcpy actions.
local CLI = noctalia.expandPath("~/.local/bin/androidconnect")
local devs, busy = {}, nil

local function parse(out)
  local list = {}
  for line in (out or ""):gmatch("[^\n]+") do
    local f = {}
    for v in (line .. "|"):gmatch("([^|]*)|") do f[#f + 1] = v end
    list[#list + 1] = { id = f[1], name = f[2], online = f[3] == "true", charge = tonumber(f[4]) or -1,
      charging = f[5] == "true", notif = tonumber(f[6]) or 0, net = f[7], signal = tonumber(f[8]) or -1,
      selected = f[9] == "true", recording = f[10] == "true", awake = f[11] == "true" }
  end
  return list
end

local function selected()
  for _, d in ipairs(devs) do if d.selected then return d end end
end

local function refresh() noctalia.runAsync(CLI .. " status", function(r) devs = parse(r and r.stdout); render() end) end

local function act(name, close)
  local d = selected()
  busy = name
  render()
  noctalia.runAsync(CLI .. " " .. name .. (d and (" " .. d.id) or ""), function() busy = nil; refresh() end)
  if close then panel.close() end
end

local function btn(glyph, text, handler, opts)
  opts = opts or {}
  return ui.button({ glyph = glyph, text = text, flexGrow = 1, controlSize = "sm",
    variant = opts.active and "default" or "ghost", tooltip = opts.tooltip, onClick = handler })
end

function render()
  local d = selected()
  local rows = {}

  -- device picker
  local picks = {}
  for i, x in ipairs(devs) do
    if i > 6 then break end
    picks[#picks + 1] = ui.button({ glyph = x.online and "device-mobile" or "device-mobile-off", text = x.name,
      flexGrow = 1, controlSize = "sm", variant = x.selected and "default" or "ghost", onClick = "onPick" .. i })
  end
  if #picks == 0 then
    panel.render(ui.column({ gap = 8, padding = 16 }, {
      ui.label({ text = "No paired phones", fontSize = 16, color = "error" }),
      ui.label({ text = "Pair your phone in the KDE Connect app first (kdeconnectd must be running).", color = "on_surface_variant", wrap = true }),
      btn("refresh", "Refresh", "onRefresh"),
    }))
    return
  end
  rows[#rows + 1] = ui.row({ gap = 4 }, picks)

  -- header
  local title = d and d.name or "?"
  local sub
  if not d or not d.online then
    sub = "Offline: open KDE Connect on the phone, same Wi-Fi"
  else
    sub = (d.charge >= 0 and ("Battery " .. d.charge .. "%" .. (d.charging and " ⚡" or "")) or "Battery ?")
      .. "  ·  " .. d.notif .. " notification" .. (d.notif == 1 and "" or "s")
      .. ((d.net ~= "" or d.signal >= 0) and ("  ·  " .. (d.net ~= "" and d.net or "") .. (d.signal >= 0 and (" " .. d.signal .. "/4") or "")) or "")
  end
  rows[#rows + 1] = ui.row({ gap = 10, align = "center" }, {
    ui.glyph({ name = (d and d.online) and (d.charging and "device-mobile-charging" or "device-mobile") or "device-mobile-off",
      size = 30, color = (d and d.online) and "primary" or "on_surface_variant" }),
    ui.column({ gap = 0, flexGrow = 1 }, {
      ui.label({ text = title, fontSize = 18 }),
      ui.label({ text = sub, fontSize = 12, color = "on_surface_variant", wrap = true }),
    }),
    ui.button({ glyph = "refresh", variant = "ghost", controlSize = "sm", tooltip = "Rediscover devices", onClick = "onRefresh" }),
  })

  rows[#rows + 1] = ui.label({ text = "KDE Connect", fontSize = 12, color = "on_surface_variant" })
  rows[#rows + 1] = ui.row({ gap = 4 }, {
    btn("device-mobile-vibration", "Ring", "onRing"),
    btn("send", "Send files", "onSend"),
  })
  rows[#rows + 1] = ui.row({ gap = 4 }, {
    btn("folder-open", "Browse", "onBrowse", { tooltip = "Mount the phone over SFTP (needs sshfs)" }),
    btn("clipboard", "Clipboard", "onClip", { tooltip = "Send this PC's clipboard to the phone" }),
  })

  rows[#rows + 1] = ui.label({ text = "Screen (adb + scrcpy: USB debugging on)", fontSize = 12, color = "on_surface_variant" })
  rows[#rows + 1] = ui.row({ gap = 4 }, {
    btn("cast", "Mirror", "onMirror", { tooltip = "Mirror and control the phone in a window" }),
    btn("camera", "Screenshot", "onShot", { tooltip = "Saved to ~/Pictures/Phone and copied" }),
  })
  rows[#rows + 1] = ui.row({ gap = 4 }, {
    btn("player-record", (d and d.recording) and "Stop rec" or "Record", "onRecord", { active = d and d.recording }),
    btn("sun", "Keep awake", "onAwake", { active = d and d.awake }),
    btn("wifi", "Wi-Fi adb", "onWifi", { tooltip = "Switch a USB-connected phone to wireless adb" }),
  })
  if busy then rows[#rows + 1] = ui.label({ text = "Working: " .. busy .. "…", fontSize = 12, color = "on_surface_variant" }) end

  panel.render(ui.column({ gap = 10, padding = 16 }, rows))
end

function onRefresh() noctalia.runAsync(CLI .. " refresh", function() refresh() end) end
function onRing() act("ring") end
function onSend() act("send", true) end
function onBrowse() act("browse", true) end
function onClip() act("clip") end
function onMirror() act("mirror", true) end
function onShot() act("screenshot") end
function onRecord() act("record") end
function onAwake() act("awake") end
function onWifi() act("wifi") end
local function pick(i) local x = devs[i]; if x then noctalia.runAsync(CLI .. " select " .. x.id, function() refresh() end) end end
function onPick1() pick(1) end
function onPick2() pick(2) end
function onPick3() pick(3) end
function onPick4() pick(4) end
function onPick5() pick(5) end
function onPick6() pick(6) end

local gen = 0
function onOpen()
  busy = nil
  gen = gen + 1
  local mine = gen
  noctalia.runStream("for i in $(seq 60); do echo; sleep 3; done", function() if mine == gen then refresh() end end)
  refresh()
end
function onClose() gen = gen + 1 end
