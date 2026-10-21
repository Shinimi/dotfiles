-- Generated from settings.json by the settings panel. Edit there, not here.
hl.config({
    general = { gaps_in = 5, gaps_out = 14, border_size = 2,
                layout = "dwindle", resize_on_border = true, snap = { enabled = true },
                col = { active_border = { colors = { "rgba(a28ae8ff)", "rgba(e39ec0ff)", "rgba(7fc4e3ff)", "rgba(a28ae8ff)" }, angle = 45 } } },
    dwindle = { smart_split = false },
    decoration = {
        rounding = 14,
        active_opacity = 0.92, inactive_opacity = 0.84,
        dim_inactive = false, dim_strength = 0.12,
        blur = { enabled = true, size = 8, passes = 3, vibrancy = 0.22,
                 brightness = 0.85, noise = 0.020, xray = false, popups = true },
        shadow = { enabled = true, range = 16, color = "rgba(a28ae855)" },
        glow = { enabled = false, range = 14, color = { colors = { "rgba(a28ae866)", "rgba(e39ec066)" }, angle = 45 } },
        screen_shader = "",
    },
    animations = { enabled = true },
    input = { sensitivity = 0.40, accel_profile = "flat",
              natural_scroll = false, scroll_factor = 1.00,
              follow_mouse = 1, kb_layout = "tr", numlock_by_default = true,
              repeat_rate = 45, repeat_delay = 400,
              scroll_method = "no_scroll" },
    cursor = { hide_on_key_press = false, inactive_timeout = 0 },
    binds = { workspace_back_and_forth = false },
    misc = { focus_on_activate = true, middle_click_paste = true,
             enable_swallow = false, swallow_regex = "^(kitty)$", mouse_move_enables_dpms = false },
})
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "linear", style = "loop" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.60, bezier = "overshot" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.27, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.62, bezier = "smoothOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.60, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.95, bezier = "snappy" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.95, bezier = "snappy", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.60, bezier = "easeInOut", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.60, bezier = "overshot", style = "slidevert" })
hl.monitor({ output = "DP-1", mode = "2560x1440@144.00", position = "0x0", scale = 1, vrr = 0, bitdepth = 8, cm = "srgb" })
hl.monitor({ output = "DP-2", mode = "1920x1080@165.01", position = "2560x0", scale = 1, vrr = 0, bitdepth = 8, cm = "srgb" })
