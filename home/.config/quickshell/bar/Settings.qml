// Loads/saves ~/.config/hypr/settings.json and applies it to Hyprland (debounced). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: s
    readonly property string file: Quickshell.env("HOME") + "/.config/hypr/settings.json"
    readonly property var defaults: ({ gaps_in: 4, gaps_out: 8, border_size: 2, rounding: 10, opacity_active: 90, opacity_inactive: 80,
        blur: true, blur_size: 7, blur_passes: 3, shadows: true, animations: true, sensitivity: 0.4, follow_mouse: true,
        middle_scroll: true, focus_on_activate: true, night_temp: 4500, glass: 60,
        accent: "tokyo", border_spin: true, dim_inactive: false, repeat_rate: 35, repeat_delay: 300, lock_minutes: 10, vibrancy: 18 })
    property var v: defaults
    property bool loaded: false

    function get(k) { return v[k] !== undefined ? v[k] : defaults[k] }
    function set(k, val) { const n = Object.assign({}, v); n[k] = val; v = n; save.restart() }
    function reset() { v = Object.assign({}, defaults); save.restart() }

    Process {
        running: true
        command: ["cat", s.file]
        stdout: StdioCollector { onStreamFinished: { try { s.v = Object.assign({}, s.defaults, JSON.parse(this.text)) } catch (e) {} s.loaded = true } }
    }
    Timer {
        id: save; interval: 350
        onTriggered: Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\" && \"$3\"", "sh",
            JSON.stringify(s.v, null, 2), s.file, Quickshell.env("HOME") + "/.config/hypr/scripts/apply-settings.sh"])
    }
}
