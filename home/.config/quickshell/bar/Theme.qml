// Shinobu Kochō palette + sizes shared by every widget. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#1a1726"
    // translucent surfaces (Hyprland blurs what's behind them); text colors stay solid
    // glass level (0-100) comes from the Hyprland settings panel
    readonly property real glass: Settings.cur("glass") / 100
    readonly property color barBg:   Qt.rgba(0.102, 0.09, 0.149, 1 - glass * 0.70)
    readonly property color panel:   Qt.rgba(0.102, 0.09, 0.149, 1 - glass * 0.45)
    readonly property color card:    Qt.rgba(0.145, 0.125, 0.2, 0.80 - glass * 0.45)
    readonly property color glassLine: "#40ece4f6" // soft light edge
    readonly property color bgAlt:   "#252033"
    readonly property color bgHover: "#2d2640"
    readonly property color border:  "#2d2640"
    readonly property color line:    "#4a3f63"
    readonly property color fg:      "#ece4f6"
    readonly property color fgDim:   "#c9bddf"
    readonly property color muted:   "#7d7299"
    readonly property color blue:    "#b69cf0"
    readonly property color cyan:    "#8fd3e0"
    readonly property color purple:  "#e49bd8"
    readonly property color green:   "#9fdcc0"
    readonly property color yellow:  "#f0c98a"
    readonly property color red:     "#f27a9e"

    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    readonly property string font:   "JetBrainsMono Nerd Font"
    readonly property int fontSize:  12
    readonly property int barHeight: 32
    readonly property int pillHeight: 26
    readonly property int radius:    9
}
