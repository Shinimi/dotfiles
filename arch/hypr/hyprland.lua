-- yu's Hyprland on vanilla Arch · minimal + monochrome. Noctalia is the whole shell (bar, launcher, control center,
-- notifications, lock + idle, wallpaper, clipboard, screenshots, password prompts). Edit, then SUPER + SHIFT + R.
-- Made by Claude.
--
-- KEYS (SUPER = Windows key)
--   SUPER + T / Return   terminal            SUPER + Space   launcher           SUPER + A        control center
--   SUPER + E            files              SUPER + B       browser            SUPER + comma    Noctalia settings
--   SUPER + V            clipboard          SUPER + period  emoji              SUPER + Y        wallpapers
--   SUPER + X            power menu         SUPER + ALT + L lock               SUPER + Q        close window
--   SUPER + F            maximize           SUPER + SHIFT+F fullscreen         SUPER + SHIFT+T  float / tile
--   SUPER + arrows/HJKL  move focus         SUPER + SHIFT + arrows  move window
--   SUPER + 1..0         workspace 1-10     SUPER + SHIFT + 1..0    send window there
--   SUPER + CTRL + arrows  other screen     Print / SUPER + SHIFT + S  screenshot
--   SUPER + ALT + N      night light        SUPER + ALT + I keep awake         SUPER + SHIFT + R  reload

local home = os.getenv("HOME")
local terminal, files, browser = "kitty", "dolphin", "helium-browser"
local function noctalia(cmd) return hl.dsp.exec_cmd("noctalia msg " .. cmd) end

---------------------------------------------------------------- screens
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@165", position = "2560x0", scale = 1 })
hl.monitor({ output = "",     mode = "preferred",     position = "auto",   scale = "auto" })

---------------------------------------------------------------- start
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("noctalia")
end)

---------------------------------------------------------------- environment
hl.env("XCURSOR_THEME", "Vimix-white-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MESA_SHADER_CACHE_MAX_SIZE", "12G")

---------------------------------------------------------------- look: monochrome glass
hl.config({
    general = {
        gaps_in = 4, gaps_out = 10, border_size = 2,
        col = { active_border = { colors = { "rgba(eaeaeaff)", "rgba(7a7a7aff)" }, angle = 45 }, inactive_border = "rgba(2a2a2aaa)" },
        layout = "dwindle", resize_on_border = true, allow_tearing = true,
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.94, inactive_opacity = 0.86,
        shadow = { enabled = true, range = 10, render_power = 3, color = 0xaa000000 },
        blur = { enabled = true, size = 7, passes = 3, noise = 0.02, brightness = 0.8, vibrancy = 0.1, popups = true },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0,
             focus_on_activate = true, vrr = 0 },
    render = { direct_scanout = 2 },
    input = {
        kb_layout = "tr", numlock_by_default = true, follow_mouse = 1,
        accel_profile = "flat", sensitivity = 0.4,
        scroll_method = "on_button_down", scroll_button = 274,   -- hold the middle button + move = scroll
    },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})
hl.curve("snappy", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "global",     enabled = true, speed = 5, bezier = "snappy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4, bezier = "snappy", style = "popin 85%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "snappy", style = "slidefade 12%" })

---------------------------------------------------------------- workspaces: 1-10 on the main screen, the side screen keeps its own
for i = 1, 10 do hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = (i == 1), persistent = (i <= 4) }) end
hl.workspace_rule({ workspace = "name:side", monitor = "DP-2", default = true, persistent = true })

---------------------------------------------------------------- window rules
local solid = "^(steam_app_[0-9]+|cs2|gamescope|mpv|kitty|vesktop|com.moonlight_stream.Moonlight)$"
hl.window_rule({ name = "solid", match = { class = solid }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ name = "games", match = { class = "^(steam_app_[0-9]+|cs2|gamescope)$" }, fullscreen_state = "2 2", immediate = true })
hl.window_rule({ name = "side-apps", match = { class = "^(vesktop|discord|Spotify|spotify)$" }, workspace = "name:side silent" })
hl.window_rule({ name = "no-idle-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })
hl.window_rule({ name = "dialogs", match = { title = "^(Open|Open File.*|Save|Save As.*|Choose .*|Select .*|File Upload|.*[Cc]opying.*|.*[Pp]rogress.*)$" },
                 float = true, center = true, size = "(monitor_w*0.55) (monitor_h*0.62)" })
hl.window_rule({ name = "tools", match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|btop)$" }, float = true, center = true })
hl.window_rule({ name = "pip", match = { title = "^([Pp]icture[- ][Ii]n[- ][Pp]icture)$" }, float = true, pin = true,
                 size = "(monitor_w*0.24) (monitor_h*0.24)", move = "(monitor_w*0.76-18) (monitor_h*0.76-18)" })
hl.window_rule({ name = "steam-popups", match = { class = "^(steam)$", title = "^(Friends List|Steam Settings|Properties.*|.*Chat.*)$" }, float = true })
hl.layer_rule({ name = "noctalia-blur", match = { namespace = "^noctalia" }, blur = true, ignore_alpha = 0.3 })

---------------------------------------------------------------- keys
local function b(keys, dsp, opts) hl.bind(keys, dsp, opts) end
local run = hl.dsp.exec_cmd
b("SUPER + T", run(terminal)); b("SUPER + Return", run(terminal))
b("SUPER + E", run(files)); b("SUPER + B", run(browser))
b("SUPER + space", noctalia("panel-toggle launcher")); b("ALT + space", noctalia("panel-toggle launcher"))
b("SUPER + A", noctalia("panel-toggle control-center"))
b("SUPER + comma", noctalia("settings-toggle"))
b("SUPER + V", noctalia("panel-toggle clipboard"))
b("SUPER + period", noctalia("panel-toggle launcher /emo"))
b("SUPER + Y", noctalia("panel-toggle wallpaper"))
b("SUPER + X", noctalia("panel-toggle session"))
b("SUPER + ALT + L", noctalia("session lock"))
b("SUPER + ALT + N", noctalia("nightlight-force-toggle"))
b("SUPER + ALT + I", noctalia("caffeine-toggle"))
b("Print", noctalia("screenshot-region")); b("SUPER + SHIFT + S", noctalia("screenshot-region"))
b("CTRL + Print", noctalia("screenshot-fullscreen"))
b("CTRL + ALT + Delete", run(terminal .. " --class btop -e btop"))
b("SUPER + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
b("SUPER + SHIFT + E", hl.dsp.exit())

b("SUPER + Q", hl.dsp.window.close())
b("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
b("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
b("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
for key, d in pairs({ left = "l", down = "d", up = "u", right = "r", H = "l", J = "d", K = "u", L = "r" }) do
    b("SUPER + " .. key, hl.dsp.focus({ direction = d }))
    b("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = d }))
end
for key, d in pairs({ left = "l", right = "r" }) do
    b("SUPER + CTRL + " .. key, hl.dsp.focus({ monitor = d }))
    b("SUPER + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = d }))
end
for i = 1, 10 do
    local key = i % 10
    b("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    b("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end
b("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" })); b("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
b("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }); b("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

b("XF86AudioRaiseVolume", noctalia("volume-up"), { locked = true, repeating = true })
b("XF86AudioLowerVolume", noctalia("volume-down"), { locked = true, repeating = true })
b("XF86AudioMute", noctalia("volume-mute"), { locked = true })
b("XF86AudioPlay", noctalia("media toggle"), { locked = true })
b("XF86AudioNext", noctalia("media next"), { locked = true })
b("XF86AudioPrev", noctalia("media previous"), { locked = true })
