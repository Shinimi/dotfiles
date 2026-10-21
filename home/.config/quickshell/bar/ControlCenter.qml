// Control center: quick toggles, sliders and actions. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

BarPopup {
    id: cc
    contentWidth: 320
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    property bool night: false
    property bool awake: false
    property bool perf: false
    function refresh() { state.running = true }
    onVisibleChanged: if (visible) refresh()
    Process {
        id: state
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo n1 || echo n0; pgrep -x hypridle >/dev/null && echo a0 || echo a1; powerprofilesctl get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text
                cc.night = t.indexOf("n1") >= 0; cc.awake = t.indexOf("a1") >= 0; cc.perf = t.indexOf("performance") >= 0
            }
        }
    }
    Timer { id: later; interval: 500; onTriggered: cc.refresh() }
    function run(cmd) { Quickshell.execDetached(cmd); later.restart() }

    component Tile: Rectangle {
        property string icon; property string title; property string sub; property bool on: false; property color accent: Theme.blue
        signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1
        height: 64; radius: 14
        color: on ? accent : (tMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
        Behavior on color { ColorAnimation { duration: 140 } }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 12
            Rectangle {
                width: 34; height: 34; radius: 17
                color: on ? Qt.rgba(0, 0, 0, 0.18) : Theme.bg
                Label { anchors.centerIn: parent; text: icon; color: on ? Theme.bg : accent; font.pixelSize: 14 }
            }
            Column {
                Layout.fillWidth: true; spacing: 1
                Label { text: title; color: on ? Theme.bg : Theme.fg; font.pixelSize: 12 }
                Label { text: sub; color: on ? Qt.rgba(0.1, 0.1, 0.15, 0.8) : Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
            }
        }
        MouseArea { id: tMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    Label { text: "Control center"; font.pixelSize: 15; font.weight: Font.Bold }

    GridLayout {
        width: parent.width; columns: 2; columnSpacing: 10; rowSpacing: 10
        Tile { icon: ""; title: "Night light"; sub: cc.night ? "On · 4500K" : "Off"; on: cc.night; accent: Theme.yellow
               onHit: cc.run([cc.scripts + "/nightlight.sh"]) }
        Tile { icon: ""; title: "Silent"; sub: Notifs.dnd ? "No pop-ups" : "Off"; on: Notifs.dnd; accent: Theme.purple
               onHit: Notifs.dnd = !Notifs.dnd }
        Tile { icon: ""; title: "Keep awake"; sub: cc.awake ? "No auto-lock" : "Off"; on: cc.awake; accent: Theme.cyan
               onHit: cc.run([cc.scripts + "/idle-inhibit.sh"]) }
        Tile { icon: ""; title: "Performance"; sub: cc.perf ? "Max power" : "Balanced"; on: cc.perf; accent: Theme.red
               onHit: cc.run(["powerprofilesctl", "set", cc.perf ? "balanced" : "performance"]) }
    }

    Rectangle {
        width: parent.width; height: sliders.implicitHeight + 24; radius: 14; color: Theme.bgAlt
        Column {
            id: sliders
            x: 12; y: 12; width: parent.width - 24; spacing: 12
            RowLayout {
                width: parent.width; spacing: 10
                Label { text: cc.sink && cc.sink.audio && cc.sink.audio.muted ? "" : ""; color: Theme.green; Layout.preferredWidth: 18
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted } }
                Slider { Layout.fillWidth: true; accent: Theme.green; value: cc.sink && cc.sink.audio ? cc.sink.audio.volume : 0
                         onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } } }
            }
            RowLayout {
                width: parent.width; spacing: 10
                Label { text: cc.source && cc.source.audio && cc.source.audio.muted ? "" : ""; color: Theme.purple; Layout.preferredWidth: 18
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted } }
                Slider { Layout.fillWidth: true; accent: Theme.purple; value: cc.source && cc.source.audio ? cc.source.audio.volume : 0
                         onMoved: v => { if (cc.source) cc.source.audio.volume = v } }
            }
        }
    }

    RowLayout {
        width: parent.width; spacing: 10
        Repeater {
            model: [
                ["", "Screenshot", ["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"]],
                ["", "Color",      ["sh", "-c", "sleep 0.3; hyprpicker -a"]],
                ["", "Wallpaper",  ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "wallpaper", "toggle"]],
                ["", "Settings",   ["systemsettings"]]
            ]
            Rectangle {
                required property var modelData
                Layout.fillWidth: true; height: 54; radius: 12
                color: qMouse.containsMouse ? Theme.bgHover : Theme.bgAlt
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: Theme.blue; font.pixelSize: 15 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: Theme.fgDim; font.pixelSize: 10; font.weight: Font.Normal }
                }
                MouseArea { id: qMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { cc.visible = false; Quickshell.execDetached(modelData[2]) } }
            }
        }
    }
}
