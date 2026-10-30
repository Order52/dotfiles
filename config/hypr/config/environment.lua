-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    SYSTEM ENVIRONMENT                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- ── Desktop Session ───────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- ── Cursor ────────────────────────────────────────────────────
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")

-- ── Toolkit Backends ──────────────────────────────────────────
-- removed SDL_VIDEODRIVER to prevent game crashes
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- ── Theming ───────────────────────────────────────────────────
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GTK_USE_PORTAL", "1")

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     HARDWARE & GPU                          ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- ── NVIDIA Stability ──────────────────────────────────────────
-- Essential for the driver to load
hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- ── DISABLED (Cause of Crashes) ──────────────────────────────
-- DO NOT enable these globally. They confuse the window manager
-- during fullscreen transitions.

-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NVD_BACKEND", "direct")

-- ── Sync & VRR ────────────────────────────────────────────────
-- If you still crash, comment these two lines out next
-- hl.env("__GL_GSYNC_ALLOWED", "1")
-- hl.env("__GL_VRR_ALLOWED", "1")

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       APPLICATIONS                          ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- ── Firefox ───────────────────────────────────────────────────
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- ── Clipboard ─────────────────────────────────────────────────
hl.env("CLIPHIST_MAX_ITEMS", "30")

-- ── System ────────────────────────────────────────────────────
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "~/.local/state/ags/.venv")
hl.env("APPIMAGELAUNCHER_DISABLE", "1")

-- Force NVIDIA as primary (card1) and fallback to Intel (card2) only if needed
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")  -- GPU ONLY
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card2")
