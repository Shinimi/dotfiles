-- Generated from settings.json by the settings panel. Edit there, not here.
hl.config({
    general = { gaps_in = 4, gaps_out = 8, border_size = 2,
                col = { active_border = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)", "rgba(7dcfffff)", "rgba(7aa2f7ff)" }, angle = 45 } } },
    decoration = {
        rounding = 10,
        active_opacity = 0.90, inactive_opacity = 0.80,
        dim_inactive = false, dim_strength = 0.12,
        blur = { enabled = true, size = 7, passes = 3, vibrancy = 0.18 },
        shadow = { enabled = true },
        screen_shader = "",
    },
    animations = { enabled = true },
    input = { sensitivity = 0.40, follow_mouse = 1,
              repeat_rate = 45, repeat_delay = 400,
              scroll_method = "on_button_down" },
    misc = { focus_on_activate = true },
})
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "linear", style = "loop" })
hl.monitor({ output = "DP-1", mode = "2560x1440@144.00", position = "0x0", scale = 1, vrr = 0, bitdepth = 8, cm = "srgb" })
hl.monitor({ output = "DP-2", mode = "1920x1080@165.01", position = "2560x0", scale = 1, vrr = 0, bitdepth = 8, cm = "srgb" })
