-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Autostart Configuration                  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

hl.on("hyprland.start", function()
    local run = hl.exec_cmd

    -- Shell
    -- Noctalia is the whole shell: bar, notifications, wallpaper, launcher, clipboard, polkit,
    -- Bluetooth + network agents, window switcher. (Hyprland re-runs this on reload, hence the guard.)
    run("pgrep -x noctalia >/dev/null || noctalia")
    run("brightnessctl set 0%")

    -- KDE Wallet
    run("/usr/lib/pam_kwallet_init")


    -- Slow app launch fix
    run("systemctl --user import-environment")
    run("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Keyboard RGB: re-apply whatever was last chosen (Noctalia RGB panel, `kbd-rgb`, or the menu).
    -- (A fixed `rgbkb wave ...` here would overwrite the saved choice at every login.)
    run("bash -c 'PATH=$HOME/.local/bin:$PATH ~/.local/share/pipx/venvs/rgbkb/bin/rgbkb apply'")


    -- KDE Connect
    run("kdeconnectd")

    -- Disabled in the old config:
    -- run("hyprpaper")
    -- run("quickshell")
    -- run("hypridle")
    -- run("sunshine")
    -- run("gammastep -l auto -t 5500:3500 -b 1.0:0.8")
end)
