-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Defaults Configuration                  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Usage: local d = require("config.defaults")  ->  d.terminal

return {
    -- ── File Manager ───────────────────────────────────────────────
    -- filemanager = "thunar",  -- Lighter than dolphin
    filemanager = "dolphin --platformtheme kde",

    -- ── Browser ────────────────────────────────────────────────────
    browser = "firefox",

    -- ── Terminal ───────────────────────────────────────────────────
    -- terminal = "kitty",
    -- terminal = "foot",
    terminal = "alacritty",

    -- ── Screen Capture ─────────────────────────────────────────────
    -- capturing = [[grim -g "$(slurp)" - | swappy -f -]],
    capturing = "grimblast --freeze save area - | swash --stdin --name swash-capture.png",

    -- ── PDF Viewer ─────────────────────────────────────────────────
    -- pdfviewer = "zathura",
    pdfviewer = "okular --platformtheme kde",

}
