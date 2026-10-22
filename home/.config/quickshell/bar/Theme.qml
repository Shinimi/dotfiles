// Monochrome palette + sizes shared by every widget. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#111111"
    // translucent surfaces (Hyprland blurs what's behind them); text colors stay solid
    // glass level (0-100) comes from the Hyprland settings panel
    readonly property real glass: Settings.cur("glass") / 100
    readonly property color barBg:   Qt.rgba(0.07, 0.07, 0.07, 1 - glass * 0.70)
    readonly property color panel:   Qt.rgba(0.07, 0.07, 0.07, 1 - glass * 0.45)
    readonly property color card:    Qt.rgba(0.11, 0.11, 0.11, 0.80 - glass * 0.45)
    readonly property color glassLine: "#40eaeaea" // soft light edge
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

    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    readonly property string font:   "GeistMono Nerd Font"
    readonly property int fontSize:  12
    readonly property int barHeight: 32
    readonly property int pillHeight: 26
    readonly property int radius:    9
}
