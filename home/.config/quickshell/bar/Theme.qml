// Monochrome palette + sizes shared by every widget. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property color bg:      "#111111"
    // translucent surfaces (Hyprland blurs what's behind them); text colors stay solid
    // glass level (0-100) comes from the Hyprland settings panel
    readonly property real glass: Settings.cur("glass") / 100
    // frosted dark glass: a deep tint the blur shows through, never grey haze
    // wallpaper tint (Settings → Extras): a little of the wallpaper's own colour mixed into the glass
    property color tint: "#808080"
    readonly property real tintOn: Settings.cur("wall_tint") ? 1 : 0
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a) }
    readonly property string tintFor: Settings.cur("wall_main")
    onTintForChanged: Qt.callLater(() => tintProc.running = true)
    property Process tintProc: Process {
        command: ["python3", "-I", Quickshell.env("HOME") + "/.config/quickshell/bar/walltint.py", Settings.cur("wall_main") || "/dev/null"]
        stdout: StdioCollector { onStreamFinished: { const c = this.text.trim(); if (/^#[0-9a-f]{6}$/.test(c)) Theme.tint = c } }
    }
    Behavior on tint { ColorAnimation { duration: 900 } }
    // frosted dark glass: a deep tint the blur shows through, never grey haze
    readonly property color barBg:   mix(Qt.rgba(0.035, 0.035, 0.035, 0.82 - glass * 0.40), tint, 0.10 * tintOn)
    readonly property color panel:   mix(Qt.rgba(0.035, 0.035, 0.035, 0.90 - glass * 0.35), tint, 0.10 * tintOn)
    // cards are light veils on the glass (not darker boxes) so layers stay clean
    readonly property color card:    mix(Qt.rgba(1, 1, 1, 0.043), tint, 0.45 * tintOn)
    readonly property color cardHi:  mix(Qt.rgba(1, 1, 1, 0.086), tint, 0.45 * tintOn)
    readonly property color stroke:  mix(Qt.rgba(1, 1, 1, 0.07), tint, 0.5 * tintOn)    // card hairline
    readonly property color glassLine: mix(Qt.rgba(1, 1, 1, 0.12), tint, 0.5 * tintOn)  // panel/bar edge
    readonly property color island:  mix(Qt.rgba(0.02, 0.02, 0.02, 0.90 - glass * 0.25), tint, 0.08 * tintOn)   // near-black glass
    readonly property color on:      mix(Qt.color("#ededed"), tint, 0.16 * tintOn)     // "on" state fill (monochrome accent)
    readonly property color onText:  "#0c0c0c"
    readonly property color bgAlt:   "#1c1c1c"
    readonly property color bgHover: "#242424"
    readonly property color border:  "#242424"
    readonly property color line:    "#3a3a3a"
    readonly property color fg:      "#eaeaea"
    readonly property color fgDim:   "#c8c8c8"
    readonly property color muted:   "#7a7a7a"
    readonly property color blue:    "#e0e0e0"
    readonly property color cyan:    "#c4c4c4"
    readonly property color purple:  "#b0b0b0"
    readonly property color green:   "#c8c8c8"
    readonly property color yellow:  "#d6d6d6"
    readonly property color red:     "#cf6b6b"

    function wsName(id) { return String(id) }
    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    readonly property string font:   "JetBrainsMono Nerd Font"
    readonly property int fontSize:  12
    readonly property int barHeight: 32
    readonly property int pillHeight: 26
    readonly property int radius:    9
}
