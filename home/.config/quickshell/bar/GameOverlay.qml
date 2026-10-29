// In-game overlay (SUPER + ALT + G): a see-through layer over the game with the time, how long you've played,
// performance, cooling, music and what you missed, plus one-click actions. Esc or the same key closes. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "."

Scope {
    id: root
    required property var screen
    property bool visible: false
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { PopupState.current = root; now = new Date(); info.running = true; Stats.refresh() }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "gameoverlay"; function toggle(): void { root.toggle() } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

    property date now: new Date()
    Timer { running: root.visible; interval: 1000; repeat: true; onTriggered: root.now = new Date() }

    // what's in front (the game) and since when game mode has been on
    property string game: ""
    property double since: 0
    Process {
        id: info
        command: ["sh", "-c", "hyprctl activewindow -j | python3 -I -c \"import json,sys;d=json.load(sys.stdin);print('t=' + (d.get('title') or d.get('class') or ''))\"; echo s=$(stat -c %Y \"$XDG_RUNTIME_DIR/gamemode.state\" 2>/dev/null || echo 0)"]
        stdout: StdioCollector { onStreamFinished: { const t = this.text.match(/^t=(.*)$/m), st = this.text.match(/^s=(\d+)/m)
                                             root.game = t ? t[1].trim() : ""; root.since = st ? parseInt(st[1]) * 1000 : 0 } }
    }
    readonly property string played: {
        if (!since) return ""
        const m = Math.max(0, Math.floor((now.getTime() - since) / 60000))
        return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
    }
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values.find(p => p.trackTitle) || null
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    function go(cmd) { root.visible = false; Quickshell.execDetached(cmd) }

    readonly property color ink: "#0b0b0b"
    readonly property color dim: "#7a7a7a"
    readonly property color line: "#26ffffff"

    component Tile: Rectangle {   // a glass block with a small spaced title
        default property alias inner: body.data
        property string title: ""; property string icon: ""
        radius: 18; color: "#cc0d0d0d"; border.width: 1; border.color: root.line
        Row {
            x: 20; y: 18; spacing: 8
            Text { text: icon; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 12 }
            Text { text: title.toUpperCase(); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.8; font.bold: true }
        }
        Item { id: body; x: 20; y: 48; width: parent.width - 40; height: parent.height - 66 }
    }
    component Big: Column {   // a number with a label under it
        property string value; property string label; property bool hot: false
        spacing: 2
        Text { text: value; color: hot ? Theme.red : "#f2f2f2"; font.family: Theme.font; font.pixelSize: 24; font.bold: true }
        Text { text: label; color: root.dim; font.family: Theme.font; font.pixelSize: 10 }
    }
    component Act: Rectangle {   // a square action button, white on hover
        property string icon; property string label; property bool on: false; signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1; height: 74; radius: 14
        color: am.containsMouse || on ? "#ededed" : "#cc141414"; border.width: 1; border.color: am.containsMouse || on ? "#ededed" : root.line
        Behavior on color { ColorAnimation { duration: 110 } }
        Column {
            anchors.centerIn: parent; spacing: 6
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: icon; color: am.containsMouse || on ? root.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 20 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: label; color: am.containsMouse || on ? root.ink : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
        }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-gameoverlay"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "#bf050505"   // the game stays visible behind
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }

        Item {
            id: box
            anchors.centerIn: parent; width: 1180; height: col.implicitHeight
            focus: true
            Keys.onEscapePressed: root.visible = false
            MouseArea { anchors.fill: parent }   // clicks inside don't close it
            opacity: root.visible ? 1 : 0; scale: root.visible ? 1 : 0.97
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: col
                width: parent.width; spacing: 14

                // ---- the time, the game, how long ----
                RowLayout {
                    Layout.fillWidth: true; spacing: 24
                    Text { text: Qt.formatTime(root.now, "HH:mm"); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 92; font.weight: Font.ExtraBold }
                    Column {
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 6
                        Text { text: Qt.formatDate(root.now, "dddd d MMMM").toUpperCase(); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2.4; font.bold: true }
                        Text { width: parent.width; elide: Text.ElideRight; text: root.game || "In game"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 24; font.bold: true }
                        Text { visible: root.played !== ""; text: "\u{f051f}  playing for " + root.played; color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 13 }
                    }
                    Text { Layout.alignment: Qt.AlignTop; text: "esc  ·  super + alt + g"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                // ---- performance · cooling · music ----
                RowLayout {
                    Layout.fillWidth: true; spacing: 14
                    Tile {
                        Layout.fillWidth: true; Layout.preferredWidth: 5; Layout.preferredHeight: 170
                        title: "Performance"; icon: "\u{f04bc}"
                        Row {
                            width: parent.width
                            Repeater {
                                model: [["CPU", Stats.d.cpu + "%", Stats.d.cpuTemp + "°  ·  " + Stats.d.cpuFreq + " GHz", Stats.d.cpuTemp >= 85],
                                        ["GPU", Stats.d.gpu + "%", Stats.d.gpuTemp + "°  ·  " + Stats.d.gpuPower + " W", Stats.d.gpuTemp >= 90],
                                        ["RAM", Stats.d.ram + "%", Stats.d.ramUsed.toFixed(1) + " GB", false],
                                        ["VRAM", (Stats.d.vramTotal > 0 ? Math.round(100 * Stats.d.vramUsed / Stats.d.vramTotal) : 0) + "%", Stats.d.vramUsed.toFixed(1) + " GB", false]]
                                Column {
                                    required property var modelData
                                    width: parent.width / 4; spacing: 4
                                    Text { text: modelData[0]; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.4; font.bold: true }
                                    Text { text: modelData[1]; color: modelData[3] ? Theme.red : "#f2f2f2"; font.family: Theme.font; font.pixelSize: 30; font.bold: true }
                                    Text { text: modelData[2]; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                    Tile {
                        Layout.fillWidth: true; Layout.preferredWidth: 3; Layout.preferredHeight: 170
                        title: "Cooling"; icon: "\u{f0210}"
                        Row {
                            width: parent.width
                            Big { width: parent.width / 3; value: Stats.d.gpuHot + "°"; label: "hotspot"; hot: Stats.d.gpuHot >= 95 }
                            Big { width: parent.width / 3; value: Stats.d.fan > 0 ? Stats.d.fan + "" : "off"; label: "fan rpm" }
                            Big { width: parent.width / 3; value: Stats.d.gpuCap + " W"; label: "gpu cap" }
                        }
                        Text { y: 62; text: Stats.d.fanOk ? "fan mode: " + Stats.d.fanMode : ""; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    Tile {
                        Layout.fillWidth: true; Layout.preferredWidth: 4; Layout.preferredHeight: 170
                        title: "Music"; icon: "\u{f075a}"
                        RowLayout {
                            width: parent.width; spacing: 14
                            ClippingRectangle {
                                width: 72; height: 72; radius: 12; color: "#1a1a1a"
                                Image { anchors.fill: parent; source: root.player ? (root.player.trackArtUrl || "") : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 144 }
                                Text { anchors.centerIn: parent; visible: !root.player || !root.player.trackArtUrl; text: "\u{f075a}"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 26 }
                            }
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { width: parent.width; elide: Text.ElideRight; text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                                Text { width: parent.width; elide: Text.ElideRight; text: root.player ? (root.player.trackArtist || root.player.identity) : "SUPER + M opens Spotify"; color: root.dim; font.family: Theme.font; font.pixelSize: 11 }
                                Row {
                                    topPadding: 6; spacing: 6; visible: !!root.player
                                    Repeater {
                                        model: root.player ? [["\u{f04ae}", () => root.player.previous()], [root.player.isPlaying ? "\u{f03e4}" : "\u{f040a}", () => root.player.togglePlaying()], ["\u{f04ad}", () => root.player.next()]] : []
                                        Rectangle {
                                            required property var modelData
                                            width: 34; height: 34; radius: 17; color: pm.containsMouse ? "#ededed" : "#222222"
                                            Text { anchors.centerIn: parent; text: modelData[0]; color: pm.containsMouse ? root.ink : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 14 }
                                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- what you missed ----
                Tile {
                    Layout.fillWidth: true; Layout.preferredHeight: 96
                    title: Notifs.missed.length ? "While you played · " + Notifs.missed.length : "While you played"; icon: "\u{f009a}"
                    Text {
                        width: parent.width; elide: Text.ElideRight; color: Notifs.missed.length ? "#d8d8d8" : root.dim; font.family: Theme.font; font.pixelSize: 12
                        text: Notifs.missed.length ? [...new Set(Notifs.missed)].slice(0, 6).join("  ·  ") : (Notifs.dnd ? "Nothing yet. Notifications stay quiet until the game closes." : "Nothing missed")
                    }
                }

                // ---- one click ----
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Act { icon: "\u{f066f}"; label: "Discord"; onHit: root.go([root.scripts + "/dropapp.sh", "chat", "vesktop|discord", "vesktop"]) }
                    Act { icon: "\u{f04c7}"; label: "Spotify"; onHit: root.go([root.scripts + "/dropapp.sh", "music", "[Ss]potify", "spotify-launcher"]) }
                    Act { icon: "\u{f0100}"; label: "Screenshot"; onHit: root.go(["sh", "-c", "sleep 0.35; " + root.scripts + "/screenshot.sh screen"]) }
                    Act { icon: "\u{f044a}"; label: "Record"; onHit: root.go([root.scripts + "/rec.sh"]) }
                    Act { icon: "\u{f009b}"; label: Notifs.dnd ? "Silent on" : "Silent"; on: Notifs.dnd; onHit: Notifs.dnd = !Notifs.dnd }
                    Act { icon: "\u{f0210}"; label: Stats.d.fanOk ? "Fan · " + Stats.d.fanMode : "Fan"
                          onHit: { if (!Stats.d.fanOk) return; const m = ["quiet", "balanced", "loud"]
                                   Quickshell.execDetached(["sudo", "-n", "/usr/local/bin/gpu-ctl", "fan", m[(m.indexOf(Stats.d.fanMode) + 1) % 3]]); refreshLater.restart() } }
                    Act { icon: "\u{f0eb5}"; label: "Library"; onHit: root.go(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "games", "toggle"]) }
                }
            }
        }
    }
    Timer { id: refreshLater; interval: 900; onTriggered: Stats.refresh() }
}
