// Settings → Display, redesigned: your screens drawn to scale (with their wallpapers) to pick one, then its
// resolution as shape tiles, refresh rate as big number tiles, colour mode as preview cards, and vibrance /
// night light with live colour strips. Screen changes still go through the 15 s "keep or revert" popup.
// host = the settings window (monitor data and helpers live there). Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Column {
    id: pg
    required property var host
    spacing: 18

    // which wallpaper each screen shows
    property var walls: ({})
    Process {
        running: pg.visible
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf(" = "), j = l.indexOf(": "), k = i > 0 ? i : j; if (k > 0) a[l.slice(0, k).trim()] = l.slice(k + (i > 0 ? 3 : 2)).trim() }
                pg.walls = a
            }
        }
    }
    readonly property var sel: host.selInfo
    readonly property string curRes: host.selCfg.mode ? host.selCfg.mode.split("@")[0] : ""
    readonly property string curRate: host.selCfg.mode ? host.selCfg.mode.split("@")[1] : ""
    function aspect(r) {
        const p = r.split("x").map(Number), g = (a, b) => b ? g(b, a % b) : a, d = g(p[0], p[1])
        const a = p[0] / d + ":" + p[1] / d
        return a === "8:5" ? "16:10" : a === "683:384" ? "16:9" : a
    }

    component Title: Row {   // small spaced-capitals heading, same as the groups
        property string text; property string icon
        x: 6; spacing: 8
        Text { text: parent.icon; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Text { text: parent.text.toUpperCase(); color: "#808080"; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; anchors.verticalCenter: parent.verticalCenter }
    }
    component Tile: Rectangle {   // a pickable tile: white when picked
        property bool on: false; signal picked()
        radius: 14; color: on ? "#ececec" : tm.containsMouse ? "#1c1c1c" : "#131313"
        border.width: 1; border.color: on ? "#ececec" : tm.containsMouse ? "#33ffffff" : "#1d1d1d"
        Behavior on color { ColorAnimation { duration: 130 } }
        scale: tm.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.picked() }
    }

    // ================= your screens, to scale =================
    Rectangle {
        id: stage
        width: parent.width; height: 250; radius: 18
        color: "#0e0e0e"; border.width: 1; border.color: "#1d1d1d"
        readonly property real minX: Math.min(...pg.host.monitors.map(m => m.x), 0)
        readonly property real minY: Math.min(...pg.host.monitors.map(m => m.y), 0)
        readonly property real spanW: Math.max(1, ...pg.host.monitors.map(m => m.x + m.width / m.scale)) - minX
        readonly property real spanH: Math.max(1, ...pg.host.monitors.map(m => m.y + m.height / m.scale)) - minY
        readonly property real k: Math.min((width - 80) / spanW, (height - 90) / spanH)
        readonly property real ox: (width - spanW * k) / 2
        readonly property real oy: 26
        Text { x: 18; y: 14; text: "Click a screen to set it up"; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 10 }
        Repeater {
            model: pg.host.monitors
            Item {
                id: mon
                required property var modelData
                readonly property bool on: pg.host.selMon === modelData.name
                x: stage.ox + (modelData.x - stage.minX) * stage.k + 6
                y: stage.oy + (modelData.y - stage.minY) * stage.k
                width: modelData.width / modelData.scale * stage.k - 12
                height: modelData.height / modelData.scale * stage.k
                Rectangle {   // the stand
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom
                    width: 8; height: 14; color: mon.on ? "#8a8a8a" : "#3a3a3a"
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; width: 54; height: 4; radius: 2; color: parent.color }
                }
                ClippingRectangle {
                    anchors.fill: parent; radius: 10; color: "#151515"
                    border.width: mon.on ? 3 : 2; border.color: mon.on ? "#ececec" : mm.containsMouse ? "#5a5a5a" : "#2e2e2e"
                    Image { anchors.fill: parent; anchors.margins: 3; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420
                            source: pg.walls[mon.modelData.name] ? "file://" + pg.walls[mon.modelData.name] : ""; opacity: mon.on ? 0.75 : 0.35
                            Behavior on opacity { NumberAnimation { duration: 160 } } }
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 7; gradient: Gradient {
                        GradientStop { position: 0; color: "#00000000" } GradientStop { position: 1; color: "#c0000000" } } }
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.name === "DP-1" ? "Main" : "Side"
                               color: "#ffffff"; font.family: Theme.font; font.pixelSize: 20; font.bold: true; style: Text.Outline; styleColor: "#60000000" }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.model || mon.modelData.name
                               color: "#d0d0d0"; font.family: Theme.font; font.pixelSize: 10; style: Text.Outline; styleColor: "#60000000" }
                    }
                    Row {   // badges along the bottom
                        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 10; spacing: 5
                        Repeater {
                            model: [mon.modelData.width + "×" + mon.modelData.height, Math.round(mon.modelData.refreshRate) + " Hz"].concat(mon.modelData.vrr ? ["VRR"] : [])
                            Rectangle { required property string modelData; width: bt.implicitWidth + 12; height: 18; radius: 9; color: "#cc0b0b0b"
                                        Text { id: bt; anchors.centerIn: parent; text: parent.modelData; color: "#e0e0e0"; font.family: Theme.font; font.pixelSize: 9 } }
                        }
                    }
                }
                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.host.selMon = mon.modelData.name }
            }
        }
        Text {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 14
            text: pg.sel ? pg.sel.name + "  ·  " + (pg.sel.name === "DP-1" ? "workspaces 1–20" : "Discord + Spotify") : ""
            color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10
        }
    }

    // ================= resolution =================
    Title { text: "Resolution · " + (pg.sel ? (pg.sel.name === "DP-1" ? "Main" : "Side") : ""); icon: "\u{f0379}" }
    Grid {
        width: parent.width; columns: 3; columnSpacing: 10; rowSpacing: 10
        Repeater {
            model: pg.host.resolutions
            Tile {
                id: rt
                required property string modelData
                required property int index
                on: pg.curRes === modelData
                width: (parent.width - 20) / 3; height: 76
                onPicked: pg.host.monChange("mode", modelData + "@" + pg.host.ratesFor(modelData)[0])
                readonly property var wh: modelData.split("x").map(Number)
                Rectangle {   // the shape of this resolution
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 44; height: 44 * rt.wh[1] / rt.wh[0]; radius: 4; color: "transparent"
                    border.width: 2; border.color: rt.on ? "#0b0b0b" : "#5a5a5a"
                }
                Column {
                    x: 74; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                    Text { text: rt.modelData.replace("x", " × "); color: rt.on ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                    Text { text: pg.aspect(rt.modelData) + (rt.index === 0 ? "  ·  native" : ""); color: rt.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }

    // ================= refresh rate =================
    Title { text: "Refresh rate"; icon: "\u{f04c5}" }
    Row {
        width: parent.width; spacing: 10
        Repeater {
            model: pg.host.ratesFor(pg.curRes)
            Tile {
                id: hz
                required property string modelData
                required property int index
                readonly property int n: pg.host.ratesFor(pg.curRes).length
                on: pg.curRate === modelData
                width: (parent.width - 10 * (n - 1)) / Math.max(n, 3); height: 92
                onPicked: pg.host.monChange("mode", pg.curRes + "@" + modelData)
                Column {
                    anchors.centerIn: parent; spacing: 2
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                        Text { text: Math.round(parseFloat(hz.modelData)); color: hz.on ? "#0b0b0b" : "#ffffff"; font.family: Theme.font; font.pixelSize: 30; font.bold: true }
                        Text { anchors.baseline: parent.children[0].baseline; text: "Hz"; color: hz.on ? "#80000000" : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: hz.index === 0 ? "Smoothest" : Math.round(parseFloat(hz.modelData)) <= 60 ? "Saves power" : "Smooth"
                           color: hz.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }

    // ================= colour =================
    Title { text: "Colour"; icon: "\u{f03d8}" }
    Row {
        width: parent.width; spacing: 10
        Repeater {
            model: [["srgb", "Accurate", "sRGB · true to life", ["#8a6f6f", "#6f8a76", "#6f7a8a", "#8a846f"]],
                    ["wide", "Vivid", "Wide gamut · punchier", ["#e04848", "#3fd16a", "#3f7ae0", "#e0c23f"]],
                    ["edid", "Monitor's own", "EDID · what it reports", ["#b85a5a", "#5ab874", "#5a7ab8", "#b8a85a"]]]
            Tile {
                id: cm
                required property var modelData
                on: (pg.host.selCfg.cm || "srgb") === modelData[0]
                width: (parent.width - 20) / 3; height: 96
                onPicked: pg.host.monChange("cm", modelData[0])
                Row {   // a little preview of how colours come out
                    x: 14; y: 14; spacing: 0
                    Repeater { model: cm.modelData[3]
                        Rectangle { required property string modelData; required property int index; width: 22; height: 22; color: modelData
                                    radius: index === 0 || index === 3 ? 6 : 0 } }
                }
                Column {
                    x: 14; y: 48; spacing: 2
                    Text { text: cm.modelData[1]; color: cm.on ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                    Text { text: cm.modelData[2]; color: cm.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }
    SetSection {
        width: parent.width
        SetSwitch {
            label: "10-bit colour"; desc: "smoother gradients, less banding (if the screen supports it)"
            on: pg.host.selCfg.bitdepth === 10; onToggled: pg.host.monChange("bitdepth", pg.host.selCfg.bitdepth === 10 ? 8 : 10)
        }
        SetSwitch {
            label: "Adaptive sync (VRR)"; desc: "smoother games below max Hz; only in fullscreen, so the desktop never flickers"
            on: !!pg.host.selCfg.vrr; onToggled: pg.host.monChange("vrr", pg.host.selCfg.vrr ? 0 : 1)
        }
    }

    // ================= vibrance + night light =================
    Row {
        width: parent.width; spacing: 14
        Column {
            width: (parent.width - 14) / 2; spacing: 8
            Title { text: "Vibrance · all screens"; icon: "\u{f0e09}" }
            Rectangle {
                width: parent.width; height: vcol.implicitHeight + 28; radius: 16; color: "#131313"; border.width: 1; border.color: "#1d1d1d"
                Column {
                    id: vcol
                    x: 16; y: 14; width: parent.width - 32; spacing: 12
                    Row {   // colours as they'd look right now
                        width: parent.width; height: 34
                        readonly property real v: Settings.get("mono_mode") ? 0 : Settings.get("vibrance") / 100
                        Repeater {
                            model: ["#d94a4a", "#e0913f", "#d9c93f", "#4ac06a", "#3f8fd9", "#8a5ad9"]
                            Rectangle {
                                required property string modelData
                                required property int index
                                readonly property color base: modelData
                                readonly property real l: 0.2126 * base.r + 0.7152 * base.g + 0.0722 * base.b
                                readonly property real v: parent.v
                                width: parent.width / 6; height: 34
                                radius: index === 0 || index === 5 ? 8 : 0
                                color: Qt.rgba(Math.max(0, Math.min(1, l + (base.r - l) * v)), Math.max(0, Math.min(1, l + (base.g - l) * v)),
                                               Math.max(0, Math.min(1, l + (base.b - l) * v)), 1)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    SetSlider { label: "Vibrance"; key: "vibrance"; from: 70; to: 150; step: 5; suffix: "%" }
                    SetToggle { label: "Monochrome mode"; desc: "everything in black and white; colours come back while you play (Super + Alt + M)"; key: "mono_mode" }
                }
            }
        }
        Column {
            width: (parent.width - 14) / 2; spacing: 8
            Title { text: "Night light"; icon: "\u{f0594}" }
            Rectangle {
                width: parent.width; height: ncol.implicitHeight + 28; radius: 16; color: "#131313"; border.width: 1; border.color: "#1d1d1d"
                Column {
                    id: ncol
                    x: 16; y: 14; width: parent.width - 32; spacing: 12
                    Item {   // warm ← → neutral, with a marker at the chosen warmth
                        width: parent.width; height: 34
                        Rectangle {
                            anchors.fill: parent; radius: 8
                            gradient: Gradient { orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "#ff8a3a" } GradientStop { position: 0.45; color: "#ffc58a" } GradientStop { position: 1; color: "#f4f4f4" } }
                            opacity: SysState.night ? 1 : 0.45
                        }
                        Rectangle {
                            x: (Settings.get("night_temp") - 2500) / 4000 * (parent.width - 4); width: 4; height: parent.height + 6; y: -3; radius: 2
                            color: "#0b0b0b"; border.width: 1; border.color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                    }
                    SetSwitch { label: "Night light"; desc: SysState.night ? "on now, " + Settings.get("night_temp") + " K" : "warmer colours at night"; on: SysState.night; onToggled: SysState.toggleNight() }
                    SetSlider { label: "Warmth"; key: "night_temp"; from: 2500; to: 6500; step: 100; suffix: " K" }
                    SetToggle { label: "On a schedule"; desc: Settings.get("night_auto") ? "from " + Settings.get("night_from") + ":00 to " + String(Settings.get("night_to")).padStart(2, "0") + ":00" : "on in the evening, off in the morning"; key: "night_auto" }
                    SetSlider { visible: Settings.get("night_auto"); label: "Turn on at"; key: "night_from"; from: 17; to: 23; suffix: ":00" }
                    SetSlider { visible: Settings.get("night_auto"); label: "Turn off at"; key: "night_to"; from: 4; to: 10; suffix: ":00" }
                }
            }
        }
    }
}
