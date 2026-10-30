-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Windowrules Configuration                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Rules are processed top to bottom; the LAST matching rule wins.
-- Percent sizes/positions from the old config are written as monitor_w/monitor_h expressions.

local rule = hl.window_rule

-- ── Float necessary windows ─────────────────────────────────────
rule({ match = { class = "^Rofi$" }, float = true })
rule({ match = { class = "^(org.pulseaudio.pavucontrol)" }, float = true })
rule({ match = { class = "^()$", title = "^(Picture in picture)$" }, float = true })
rule({ match = { class = "^()$", title = "^(Save File)$" }, float = true })
rule({ match = { class = "^()$", title = "^(Open File)$" }, float = true })
rule({ match = { class = "^(LibreWolf)$", title = "^(Picture-in-Picture)$" }, float = true })
rule({ match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|xdg-desktop-portal-hyprland)(.*)$" }, float = true })
rule({ match = { class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent|org.org.kde.polkit-kde-authentication-agent-1)(.*)$" }, float = true })
rule({ match = { class = "^(CachyOSHello)$" }, float = true })
rule({ match = { class = "^(zenity)$" }, float = true })
rule({ match = { class = "^()$", title = "^(Steam - Self Updater)$" }, float = true })

-- ── Opacity ─────────────────────────────────────────────────────
rule({ match = { class = "^(thunar|nemo|dolphin)$" }, opacity = "0.92" })
-- rule({ match = { class = "^(discord|vesktop|armcord|webcord)$" }, opacity = "0.96" })
rule({ match = { title = "^(QQ|Telegram)$" }, opacity = "0.95" })
rule({ match = { title = "^(NetEase Cloud Music Gtk4)$" }, opacity = "0.95" })

-- ── General window rules ────────────────────────────────────────
rule({
    match = { title = "^(Picture-in-Picture)$" },
    float = true, size = { 960, 540 }, move = { "monitor_w*0.75", "monitor_h*0.75" },
})
rule({
    match = { title = "^(imv|mpv|danmufloat|termfloat|nemo|ncmpcpp)$" },
    float = true, size = { 960, 540 }, move = { "monitor_w*0.75", "monitor_h*0.75" },
})
rule({ match = { title = "^(danmufloat)$" }, pin = true })
rule({ match = { title = "^(danmufloat|termfloat)$" }, rounding = 5 })
rule({ match = { class = "^(kitty|Alacritty)$" }, animation = "slide right" })
rule({ match = { class = "^(org.mozilla.firefox)$" }, no_blur = true })
rule({ match = { class = "^(Brave-browser)$" }, no_blur = true })
rule({ match = { class = "^Brave-browser$", title = "^YouTube$" }, tile = true })

-- Decorations for floating windows on workspaces 1 to 10
rule({ match = { float = true, workspace = "w[fv1-10]" }, border_size = 2, rounding = 20 })
-- rule({ match = { float = true, workspace = "w[fv1-10]" }, border_color = c.cachylblue })
-- Decorations for tiling windows on workspaces 1 to 10
rule({ match = { float = false, workspace = "f[1-10]" }, border_size = 2, rounding = 20 })

-- ── Workspace rules ─────────────────────────────────────────────
-- Smart gaps (replaces the removed no_gaps_when_only)
hl.workspace_rule({ workspace = "w[tv1-10]", gaps_out = 5, gaps_in = 3 })
hl.workspace_rule({ workspace = "f[1]",      gaps_out = 5, gaps_in = 3 })

-- ── General improvements ────────────────────────────────────────
rule({ match = { xwayland = true }, no_blur = true })
rule({ match = { float = false }, no_shadow = true })

-- Dialog windows – center + float common file pickers
rule({
    match = { title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload)(.*)$" },
    center = true, float = true,
})

-- Picture-in-Picture
rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true, keep_aspect_ratio = true, pin = true,
    move = { "monitor_w*0.73", "monitor_h*0.72" },
    size = { "monitor_w*0.25", "monitor_h*0.25" },
})

-- Floating + sizing for settings/connection GUIs
rule({
    match = { class = "^(nm-connection-editor|pavucontrol|org.pulseaudio.pavucontrol)$" },
    float = true, center = true, size = { "monitor_w*0.45", "monitor_h*0.5" },
})
rule({ match = { class = "^(steam|blueberry\\.py|guifetch)$" }, float = true })

-- Force tiled layout for known apps
rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Tearing fixes (only if using Wine/Proton games/tools)
rule({ match = { title = ".*\\.exe" }, immediate = true })
rule({ match = { class = "^(steam_app)" }, immediate = true })

rule({ match = { class = "gsimplecal" }, float = true, size = { 204, 172 }, move = { 1181, 42 } })

-- KDE file picker
rule({
    match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$" },
    float = true, size = { 1084, 827 },
})

-- Fix some dragging issues with XWayland
rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Screenshot annotators (swash / satty)
rule({
    match = { class = "^(dev\\.lemmy\\.swash)$" },
    float = true, center = true, size = { "monitor_w*0.8", "monitor_h*0.8" },
})

-- Screenshot (satty)
rule({
    match = { class = "^(com.gabm.satty|satty)$" },
    float = true, center = true, size = { "monitor_w*0.8", "monitor_h*0.8" },
})

-- Flameshot (set `monitor` to your leftmost monitor id)
rule({
    match = { class = "^(flameshot)$" },
    no_anim = true, float = true, move = { 0, 0 }, pin = true, monitor = "0",
})
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=sway flameshot gui"))

-- Music (Gapless)
rule({
    match = { class = "^(com\\.github\\.neithern\\.g4music)$" },
    float = true, size = { 356, 573 }, move = { 2202, 1025 },
})
-- rule({ match = { class = "^(com\\.github\\.neithern\\.g4music)$" }, pin = true })

-- ── No screen share ─────────────────────────────────────────────
rule({ match = { class = "^(org\\.telegram\\.desktop)$" },  no_screen_share = true })
rule({ match = { class = "^(com\\.ayugram\\.desktop)$" },   no_screen_share = true })
rule({ match = { class = "^(org\\.keepassxc\\.KeePassXC)$" }, no_screen_share = true })
rule({ match = { class = "^(com\\.obsproject\\.Studio)$" }, no_screen_share = true })
rule({ match = { class = "^(vesktop)$" },   no_screen_share = true })
rule({ match = { class = "^(discord)$" },   no_screen_share = true })
rule({ match = { class = "^(signal)$" },    no_screen_share = true })
rule({ match = { title = "^(gsr ui)$" },    no_screen_share = true })
rule({ match = { class = "^(FreeTube)$" },  no_screen_share = true })
rule({ match = { class = "io.ente.auth" },  no_screen_share = true, float = true, size = { 441, 746 } })
rule({ match = { class = "^(librewolf)$" }, no_screen_share = true })

-- Waydroid
rule({ match = { class = "^(Waydroid)$" }, float = true, center = true, size = { 800, 1280 } })

-- Draw (gromit-mpx)
hl.workspace_rule({ workspace = "special:gromit", gaps_in = 0, gaps_out = 0 })
rule({
    match = { class = "^(Gromit-mpx)$" },
    no_blur = true, opacity = "1 1", no_shadow = true, size = { "monitor_w", "monitor_h" },
})

-- OpenBoard: block its own fullscreen request
rule({ match = { class = "org.oe-f.openboard" }, suppress_event = "fullscreen" })

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              Additions from cachyos-new-rice                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Remember the size of floating windows between launches
rule({ match = { float = true }, persistent_size = true })

-- Ignore maximize requests from all apps
rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

-- ── Gaming: send games to a dedicated, fullscreen-friendly workspace ──
local gamingApps = "^(steam_app.*|gamescope)$"
local gamingWorkspace = "name:gaming"
hl.workspace_rule({ workspace = gamingWorkspace, default = true })

rule({ match = { content = "game" }, workspace = gamingWorkspace })
rule({
    match = { xdg_tag = "^(.*game.*)$" },
    workspace = gamingWorkspace, fullscreen_state = "2 2", content = "game", sync_fullscreen = true,
})
rule({ match = { class = gamingApps }, workspace = gamingWorkspace })
rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })
rule({
    match = { class = "^(steam)$", title = "^(Launching\\.{3})$" },
    float = true, center = true, workspace = gamingWorkspace,
})
rule({
    match = { class = gamingApps, title = "^(.+)$" },
    content = "game", decorate = false, fullscreen_state = "2 2",
    size = { "monitor_w", "monitor_h" }, sync_fullscreen = true,
})
rule({
    match = { class = "^(steam_app.*)$", initial_title = "^$" },
    center = true, float = true, fullscreen = false, fullscreen_state = "0 0",
    workspace = gamingWorkspace,
})

-- ── Apps ──────────────────────────────────────────────────────────
rule({ match = { class = "^(.*\\.exe)$", float = true }, center = true, fullscreen_state = "0 0" })
rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true })
rule({
    match = { class = "^(.*[Cc]alc.*)$" },
    float = true, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" },
})
rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
rule({
    match = { class = "^(org\\.kde\\.ark)$" },
    size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" },
})

-- Keep terminals, browsers and video players fully opaque (rice sets 0.95/0.85 globally)
rule({ match = { class = "^(firefox|zen|Brave-browser)$" }, opacity = "1.0 override" })
rule({ match = { class = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$" }, opacity = "1.0 override" })
rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- ── Float utility windows ─────────────────────────────────────────
for _, m in ipairs({
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}) do rule({ match = m, float = true }) end

-- ── Float common modals / dialogs ─────────────────────────────────
for _, m in ipairs({
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$" },
}) do rule({ match = m, float = true }) end

-- ── Bloodborne PC port (Lutris/Wine) ─────────────────────────────
-- The game draws its own frame: no transparency, dimming, blur or shadow on it, and let it
-- tear/present immediately. bb-probe.exe is the actual game window; bloodborne.exe is the launcher.
rule({
    name  = "bloodborne-no-effects",
    match = { class = "^(bb-probe\\.exe|bloodborne\\.exe)$" },
    opaque = true, no_dim = true, no_blur = true, no_shadow = true, immediate = true,
})
-- Game window: floating, centered, sized to its 2560x1440 output (not squeezed into a tile)
rule({
    name  = "bloodborne-game-window",
    match = { class = "^(bb-probe\\.exe)$" },
    float = true, center = true, size = { 2560, 1440 }, idle_inhibit = "focus",
})
