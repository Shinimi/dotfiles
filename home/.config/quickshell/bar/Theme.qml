// Shinobu Kochō palette + sizes shared by every widget. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#13121c"
    // translucent surfaces (Hyprland blurs what's behind them); text colors stay solid
    // glass level (0-100) comes from the Hyprland settings panel
    readonly property real glass: Settings.cur("glass") / 100
    readonly property color barBg:   Qt.rgba(0.07, 0.07, 0.11, 1 - glass * 0.70)
    readonly property color panel:   Qt.rgba(0.07, 0.07, 0.11, 1 - glass * 0.45)
    readonly property color card:    Qt.rgba(0.13, 0.12, 0.20, 0.80 - glass * 0.45)
    readonly property color glassLine: "#40efeaf8" // soft light edge
    readonly property color bgAlt:   "#221f33"
    readonly property color bgHover: "#2a2640"
    readonly property color border:  "#2a2640"
    readonly property color line:    "#403a5c"
    readonly property color fg:      "#efeaf8"
    readonly property color fgDim:   "#cfc8e2"
    readonly property color muted:   "#807a9c"
    readonly property color blue:    "#a28ae8"
    readonly property color cyan:    "#7fc4e3"
    readonly property color purple:  "#e39ec0"
    readonly property color green:   "#8fd6b8"
    readonly property color yellow:  "#eec48e"
    readonly property color red:     "#ec6f8f"

    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    readonly property string font:   "GeistMono Nerd Font"
    readonly property int fontSize:  12
    readonly property int barHeight: 32
    readonly property int pillHeight: 26
    readonly property int radius:    9
}
