-- ============================================================================
--  Hyprland config for yu's CachyOS PC  (Hyprland 0.56, Lua config)
--  Ryzen 7 5700X + RX 9060 XT | Valkyrie 1440p144 (DP-1) + ViewSonic 1080p165 (DP-2)
--  Theme: Tokyo Night, solid windows (no transparency), snappy animations.
--  Made by Claude. Wiki: https://wiki.hypr.land/Configuring/Start/
--
--  KEYBINDS — DankMaterialShell layout  (SUPER = Windows key)
--    SUPER + T / Return      terminal (kitty)
--    SUPER + Space           app launcher        ALT + Space        app launcher
--    SUPER + V               clipboard history   SUPER + A          control center (notifications)
--    SUPER + CTRL + N        notification center SUPER + comma      settings
--    SUPER + Tab / O         window switcher     SUPER + X          power menu
--    SUPER + Q               close window
--    SUPER + F               maximize            SUPER + SHIFT + F  fullscreen
--    SUPER + SHIFT + T       float / tile        SUPER + W          group (tabs)
--    SUPER + R               toggle split        SUPER + [ / ]      preselect left / right
--    SUPER + arrows / HJKL   move focus          + SHIFT            move window
--    SUPER + CTRL + arrows / HJKL  focus monitor + SHIFT + CTRL     move window to monitor
--    SUPER + 1..9            workspace           SUPER + SHIFT + 1..9  send window there
--                            (1-4 = main 1440p screen, 5-9 = side screen)
--    SUPER + U / I, PgDn/PgUp next / prev workspace  (+ SHIFT move window)
--    SUPER + SHIFT + S       screenshot a region (copied automatically, like Windows 11)
--    SUPER + S               scratchpad          SUPER + CTRL + SHIFT + S  send to scratchpad
--    SUPER + minus / equal   narrower / wider    + SHIFT            shorter / taller
--    SUPER + mouse L / R     drag / resize
--    SUPER + ALT + L         lock screen         SUPER + SHIFT + E  log out
--    SUPER + ALT + N         night light         SUPER + ALT + I    idle inhibit (no auto-lock)
--    SUPER + SHIFT + C       color picker        SUPER + SHIFT + P  screens off / on
--    CTRL + ALT + Delete / M task manager (btop)
--    Print                   region screenshot   CTRL + Print       full screen   ALT + Print  window
--    SUPER + SHIFT + /  or  SUPER + F1   show this list
-- ============================================================================


---------------------------------------------------------------- COLORS
-- Tokyo Night palette
local c = {
    bg      = "1a1b26",
    bg_dark = "16161e",
    bg_hl   = "292e42",
    fg      = "c0caf5",
    comment = "565f89",
    blue    = "7aa2f7",
    purple  = "bb9af7",
    cyan    = "7dcfff",
    border  = "414868",
}
local function rgba(hex, a) return "rgba(" .. hex .. (a or "ff") .. ")" end


---------------------------------------------------------------- MONITORS
-- VRR is off on purpose (it made the screens flicker).
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0",    scale = 1, vrr = 0 })
hl.monitor({ output = "DP-2", mode = "1920x1080@165", position = "2560x0", scale = 1, vrr = 0 })
-- Anything else plugged in later: sensible default
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


---------------------------------------------------------------- PROGRAMS
local terminal    = "kitty"
local fileManager = "dolphin"
local browser     = "helium-browser"
local menu        = "rofi -show drun"
local scripts     = os.getenv("HOME") .. "/.config/hypr/scripts"


---------------------------------------------------------------- AUTOSTART
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")   -- password prompts (sudo dialogs)
    hl.exec_cmd("hyprpaper")                                 -- wallpaper
    hl.exec_cmd("qs -p ~/.config/quickshell/bar")           -- top bar (custom Quickshell)
    hl.exec_cmd("hypridle")                                  -- lock / screen off when idle
    hl.exec_cmd("nm-applet --indicator")                     -- network tray icon
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")  -- clipboard history
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
end)


---------------------------------------------------------------- ENVIRONMENT
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")          -- KDE apps keep your Breeze Dark look
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- Vesktop / Spotify / Steam UI on Wayland


---------------------------------------------------------------- LOOK AND FEEL
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { rgba(c.blue), rgba(c.purple) }, angle = 45 },
            inactive_border = rgba(c.border, "aa"),
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,
        active_opacity   = 1.0,   -- solid windows, no transparency
        inactive_opacity = 1.0,
        dim_inactive     = false,
        shadow = {
            enabled      = true,
            range        = 6,
            render_power = 3,
            color        = 0xaa000000,
        },
        blur = { enabled = false },  -- nothing is transparent, so no blur needed
    },

    animations = { enabled = true },
})

-- Snappy animations: short and subtle, nothing bouncy.
hl.curve("snappy", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},    {1, 1}    } })

hl.animation({ leaf = "global",      enabled = true, speed = 6,   bezier = "snappy" })
hl.animation({ leaf = "windows",     enabled = true, speed = 3,   bezier = "snappy" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.5, bezier = "snappy", style = "popin 90%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1.5, bezier = "linear", style = "popin 90%" })
hl.animation({ leaf = "border",      enabled = true, speed = 4,   bezier = "snappy" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2,   bezier = "snappy" })
hl.animation({ leaf = "layers",      enabled = true, speed = 2.5, bezier = "snappy", style = "fade" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2.5, bezier = "snappy", style = "slide" })

hl.config({
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        vrr = 0,
        focus_on_activate = true,
        middle_click_paste = true,
        key_press_enables_dpms = true,
    },
})


---------------------------------------------------------------- INPUT
hl.config({
    input = {
        kb_layout = "tr",            -- Turkish Q, same as your KDE setup
        numlock_by_default = true,
        follow_mouse = 1,

        -- Mouse: flat (no acceleration), same speed as on KDE
        accel_profile = "flat",
        sensitivity   = 0.4,

        -- Hold middle button + move = scroll (like on KDE)
        scroll_method = "on_button_down",
        scroll_button = 274,
    },
})


---------------------------------------------------------------- WORKSPACES
-- 1-4 always exist on the main 1440p screen (shown in the bar); 5-9 live on the side screen.
for i = 1, 9 do
    hl.workspace_rule({
        workspace  = tostring(i),
        monitor    = (i <= 4) and "DP-1" or "DP-2",
        default    = (i == 1 or i == 5),
        persistent = (i <= 4 or i == 5),
    })
end


---------------------------------------------------------------- WINDOW RULES
hl.window_rule({   -- ignore apps that try to maximize themselves
    name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize",
})
hl.window_rule({   -- XWayland drag fix (from the default config)
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({   -- don't lock / blank the screen while something is fullscreen (games, videos)
    name = "no-idle-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen",
})
-- Small utility windows float
for _, cls in ipairs({ "^(pavucontrol|org.pulseaudio.pavucontrol)$", "^(nm-connection-editor)$",
                       "^(blueman-manager)$", "^(org.kde.polkit-kde-authentication-agent-1)$",
                       "^(hyprpolkitagent)$", "^(btop)$" }) do
    hl.window_rule({ name = "float-" .. cls, match = { class = cls }, float = true })
end


---------------------------------------------------------------- KEYBINDS
-- Layout follows DankMaterialShell's defaults (duxlabs-dev/dux-shell hypr-binds.lua),
-- with DMS panels mapped to the tools used here (rofi, swaync, hyprlock, ...).
local mod = "SUPER"
local function b(keys, dsp, opts) hl.bind(keys, dsp, opts) end
local run = hl.dsp.exec_cmd
local rep = { repeating = true }

-- Launchers & panels
b("SUPER + T",              run(terminal))
b("SUPER + Return",         run(terminal))
b("SUPER + space",          run(menu))
b("ALT + space",            run(menu))
b("SUPER + V",              run("cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy"))
b("SUPER + comma",          run("systemsettings"))
b("SUPER + A",              run("qs ipc -p ~/.config/quickshell/bar call bar notifications"))
b("SUPER + CTRL + N",       run("qs ipc -p ~/.config/quickshell/bar call bar notifications"))
b("SUPER + TAB",            run("rofi -show window"))
b("SUPER + O",              run("rofi -show window"))
b("SUPER + X",              run("qs ipc -p ~/.config/quickshell/bar call bar power"))
b("SUPER + E",              run(fileManager))
b("SUPER + B",              run(browser))
b("SUPER + Y",              run("qs ipc -p ~/.config/quickshell/bar call wallpaper toggle"))
b("SUPER + SHIFT + C",      run("hyprpicker -a"))
b("SUPER + ALT + N",        run(scripts .. "/nightlight.sh"))
b("SUPER + ALT + I",        run(scripts .. "/idle-inhibit.sh"))
b("SUPER + SHIFT + Slash",  run(scripts .. "/keybinds.sh"))
b("SUPER + F1",             run(scripts .. "/keybinds.sh"))
b("SUPER + SHIFT + R",      run("hyprctl reload"))

-- Alt+Tab workspace switcher (hold Alt, tap Tab, release Alt)
local qsAlt = "qs ipc -p ~/.config/quickshell/bar call alttab "
b("ALT + Tab",              run(qsAlt .. "next"))
b("ALT + SHIFT + Tab",      run(qsAlt .. "prev"))
b("ALT + Escape",           run(qsAlt .. "cancel"))
b("ALT + ALT_L",            run(qsAlt .. "confirm"), { release = true, non_consuming = true })

-- Session
b("SUPER + ALT + L",        run("loginctl lock-session"))
b("SUPER + SHIFT + E",      hl.dsp.exit())
b("CTRL + ALT + Delete",    run(terminal .. " --class btop -e btop"))
b("CTRL + ALT + M",         run(terminal .. " --class btop -e btop"))
b("SUPER + SHIFT + P",      hl.dsp.dpms({ action = "toggle" }))

-- Windows
b("SUPER + Q",              hl.dsp.window.close())
b("SUPER + F",              hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
b("SUPER + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
b("SUPER + CTRL + F",       hl.dsp.window.fullscreen({ mode = "maximized",  action = "set" }))
b("SUPER + SHIFT + T",      hl.dsp.window.float({ action = "toggle" }))
b("SUPER + W",              hl.dsp.group.toggle())
b("SUPER + R",              hl.dsp.layout("togglesplit"))
b("SUPER + bracketleft",    hl.dsp.layout("preselect l"))
b("SUPER + bracketright",   hl.dsp.layout("preselect r"))
b("SUPER + Home",           hl.dsp.focus({ window = "first" }))
b("SUPER + End",            hl.dsp.focus({ window = "last" }))

-- Focus / move: arrows and H J K L
for key, d in pairs({ left = "l", down = "d", up = "u", right = "r", H = "l", J = "d", K = "u", L = "r" }) do
    b("SUPER + " .. key,                 hl.dsp.focus({ direction = d }))
    b("SUPER + SHIFT + " .. key,         hl.dsp.window.move({ direction = d }))
    b("SUPER + SHIFT + CTRL + " .. key,  hl.dsp.window.move({ monitor = d }))
end
for key, d in pairs({ left = "l", right = "r", H = "l", J = "d", K = "u", L = "r" }) do
    b("SUPER + CTRL + " .. key,          hl.dsp.focus({ monitor = d }))
end

-- Workspaces
for i = 1, 9 do
    b("SUPER + " .. i,          hl.dsp.focus({ workspace = tostring(i) }))
    b("SUPER + SHIFT + " .. i,  hl.dsp.window.move({ workspace = tostring(i) }))
end
b("SUPER + Page_Down",          hl.dsp.focus({ workspace = "e+1" }))
b("SUPER + Page_Up",            hl.dsp.focus({ workspace = "e-1" }))
b("SUPER + U",                  hl.dsp.focus({ workspace = "e+1" }))
b("SUPER + I",                  hl.dsp.focus({ workspace = "e-1" }))
b("SUPER + CTRL + down",        hl.dsp.window.move({ workspace = "e+1" }))
b("SUPER + CTRL + up",          hl.dsp.window.move({ workspace = "e-1" }))
b("SUPER + CTRL + U",           hl.dsp.window.move({ workspace = "e+1" }))
b("SUPER + CTRL + I",           hl.dsp.window.move({ workspace = "e-1" }))
b("SUPER + SHIFT + Page_Down",  hl.dsp.window.move({ workspace = "e+1" }))
b("SUPER + SHIFT + Page_Up",    hl.dsp.window.move({ workspace = "e-1" }))
b("SUPER + SHIFT + U",          hl.dsp.window.move({ workspace = "e+1" }))
b("SUPER + SHIFT + I",          hl.dsp.window.move({ workspace = "e-1" }))
b("SUPER + S",                  hl.dsp.workspace.toggle_special())
b("SUPER + CTRL + SHIFT + S",   hl.dsp.window.move({ workspace = "special", follow = false }))
b("SUPER + SHIFT + S",          run(scripts .. "/screenshot.sh region"))   -- Win11-style snip
b("SUPER + CTRL + S",           hl.dsp.window.move({ workspace = "+0" }))
b("SUPER + mouse_down",         hl.dsp.focus({ workspace = "e+1" }))
b("SUPER + mouse_up",           hl.dsp.focus({ workspace = "e-1" }))
b("SUPER + CTRL + mouse_down",  hl.dsp.window.move({ workspace = "e+1" }))
b("SUPER + CTRL + mouse_up",    hl.dsp.window.move({ workspace = "e-1" }))

-- Mouse + manual sizing
b("SUPER + mouse:272",          hl.dsp.window.drag(),   { mouse = true })
b("SUPER + mouse:273",          hl.dsp.window.resize(), { mouse = true })
b("SUPER + minus",              hl.dsp.window.resize({ x = -100, y = 0,    relative = true }), rep)
b("SUPER + equal",              hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }), rep)
b("SUPER + SHIFT + minus",      hl.dsp.window.resize({ x = 0,    y = -100, relative = true }), rep)
b("SUPER + SHIFT + equal",      hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }), rep)

-- Screenshots
b("Print",                      run(scripts .. "/screenshot.sh region"))
b("CTRL + Print",               run(scripts .. "/screenshot.sh full"))
b("ALT + Print",                run(scripts .. "/screenshot.sh window"))

-- Media / volume (3% steps like DMS)
b("XF86AudioRaiseVolume", run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+"), { locked = true, repeating = true })
b("XF86AudioLowerVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-"),      { locked = true, repeating = true })
b("XF86AudioMute",        run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
b("XF86AudioMicMute",     run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
b("XF86AudioPlay",        run("playerctl play-pause"), { locked = true })
b("XF86AudioPause",       run("playerctl play-pause"), { locked = true })
b("XF86AudioPrev",        run("playerctl previous"),   { locked = true })
b("XF86AudioNext",        run("playerctl next"),       { locked = true })
b("CTRL + XF86AudioRaiseVolume", run("playerctl volume 0.03+"), { locked = true, repeating = true })
b("CTRL + XF86AudioLowerVolume", run("playerctl volume 0.03-"), { locked = true, repeating = true })
