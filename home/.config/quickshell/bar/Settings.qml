// Settings store for ~/.config/hypr/settings.json. The settings panel edits a draft; nothing changes
// until Apply (then it's saved and apply-settings.sh pushes it to Hyprland, the bar and the theme).
// get() = draft (what the panel shows), cur() = applied (what the bar uses). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: s
    readonly property string file: Quickshell.env("HOME") + "/.config/hypr/settings.json"
    readonly property var defaults: ({
        // windows & look
        gaps_in: 4, gaps_out: 8, border_size: 2, rounding: 10, accent: "mono", border_spin: true, border_angle: 45,
        glow: false, glow_range: 14, glow_strength: 40, shadows: true, shadow_range: 6, shadow_tint: false,
        dim_inactive: false, dim_strength: 12, layout: "dwindle", smart_split: false, snap: true, resize_on_border: true,
        // motion
        animations: true, anim_speed: "normal", butterflies: true, butterfly_count: 7, ws_anim: "slidefade",
        // glass
        opacity_active: 80, opacity_inactive: 72, glass: 60, blur: true, blur_size: 6, blur_passes: 3, vibrancy: 15,
        blur_brightness: 62, blur_noise: 1, blur_xray: false, blur_popups: true,
        // input
        sensitivity: 0.4, accel_flat: true, natural_scroll: false, scroll_factor: 1.0, follow_mouse: true,
        middle_scroll: true, scroll_mode: "autoscroll", middle_paste: true, focus_on_activate: true, repeat_rate: 35, repeat_delay: 300,
        kb_layout: "tr", numlock: true, hide_cursor_typing: false, cursor_hide_after: 0, ws_back_forth: false, swallow: false,
        // display
        night_temp: 4500, night_auto: false, night_from: 21, night_to: 7, vibrance: 100, monitors: ({}),
        // theme
        folder_color: "grey", icon_base: "Tela-mono", cursor_theme: "Vimix-white-cursors", cursor_size: 24,
        ui_font: "Noto Sans", ui_font_size: 10, fetch_logo: "katana", fetch_source: "",
        // bar & notifications
        clock_seconds: false, clock_12h: false, clock_date: true, bar_media: true,
        notif_timeout: 5, notif_center: false, sounds: false, desktop_clock: true, desktop_clock_pos: "left",
        // power
        lock_minutes: 10, screen_off_after: 1, mouse_wakes: false, game_mode: true,
        // account, wallpaper, apps, time
        user_name: "yu", avatar: "", cc_logo: "avatar", wall_main: "", wall_side: "", default_apps: ({}), autostart: [],
        weather_place: "", weather_label: "", game_profiles: ({}),
        // extras
        hot_corner: true, instant_apply: false, confirm_power: true, volume_step: 3, shot_save: true, wall_shuffle: 0, pause_on_lock: true, island_peeks: true, screensaver: true, ws_kanji: false, auto_pause: true, sort_downloads: true, screen_time: true, game_workspace: true, wall_tint: true, ascii_wall: false, ws_preview: true, login_handoff: true, mono_mode: false, music_stats: true, break_reminder: false
    })
    property var v: defaults        // applied
    property var draft: defaults    // being edited
    property bool loaded: false
    readonly property var changedKeys: {
        const out = []
        for (const k in draft) if (JSON.stringify(draft[k]) !== JSON.stringify(v[k])) out.push(k)
        return out
    }
    readonly property bool dirty: changedKeys.length > 0
    signal applied(var keys)

    function get(k) { return draft[k] !== undefined ? draft[k] : defaults[k] }
    function cur(k) { return v[k] !== undefined ? v[k] : defaults[k] }
    function set(k, val) { const n = Object.assign({}, draft); n[k] = val; draft = n; if (k !== "instant_apply" && cur("instant_apply")) applyLater.restart() }
    Timer { id: applyLater; interval: 350; onTriggered: s.apply() }   // instant apply: sliders settle first
    function setMon(name, field, val, live) {
        const all = Object.assign({}, get("monitors"))
        all[name] = Object.assign({}, live || {}, all[name] || {}); all[name][field] = val
        set("monitors", all)
    }
    function apply() {
        if (!dirty) return
        const keys = changedKeys
        v = Object.assign({}, draft); save.restart(); applied(keys)
    }
    function discard() { draft = Object.assign({}, v) }
    function reset() { draft = Object.assign({}, defaults) }
    // for scripts (qs ipc … settings set): change and apply at once
    function setNow(k, val) { set(k, val); apply() }

    function reload() { loader.running = true }
    Process {
        id: loader
        running: true
        command: ["cat", s.file]
        stdout: StdioCollector {
            onStreamFinished: {
                try { s.v = Object.assign({}, s.defaults, JSON.parse(this.text)) } catch (e) {}
                s.draft = Object.assign({}, s.v); s.loaded = true
            }
        }
    }
    Timer {
        id: save; interval: 150
        onTriggered: Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\" && \"$3\"", "sh",
            JSON.stringify(s.v, null, 2), s.file, Quickshell.env("HOME") + "/.config/hypr/scripts/apply-settings.sh"])
    }
}
