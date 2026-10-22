// Monochrome palette + sizes shared by every widget. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#111111"
    // translucent surfaces (Hyprland blurs what's behind them); text colors stay solid
    // glass level (0-100) comes from the Hyprland settings panel
    readonly property real glass: Settings.cur("glass") / 100
    // frosted dark glass: a deep tint the blur shows through, never grey haze
    readonly property color barBg:   Qt.rgba(0.035, 0.035, 0.035, 0.82 - glass * 0.40)
    readonly property color panel:   Qt.rgba(0.035, 0.035, 0.035, 0.90 - glass * 0.35)
    // cards are light veils on the glass (not darker boxes) so layers stay clean
    readonly property color card:    "#0bffffff"
    readonly property color cardHi:  "#16ffffff"
    readonly property color stroke:  "#12ffffff"   // card hairline
    readonly property color glassLine: "#1fffffff" // panel/bar edge
    readonly property color island:  Qt.rgba(0.02, 0.02, 0.02, 0.90 - glass * 0.25)   // the dynamic island: near-black glass
    readonly property color on:      "#ededed"     // "on" state fill (monochrome accent)
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

    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    readonly property string font:   "GeistMono Nerd Font"
    readonly property int fontSize:  12
    readonly property int barHeight: 34
    readonly property int pillHeight: 26
    readonly property int radius:    9
}
