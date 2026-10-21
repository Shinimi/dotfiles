// Control center hub: toggles, sound, apps, system, notifications, tray, updates, actions. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

BarPopup {
    id: cc
    contentWidth: 680
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].concat(cc.sinks) }

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
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }


    // ---------- header ----------
    RowLayout {
        width: parent.width
        Label { text: "Control center"; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
        Label { text: "  up " + Stats.d.uptime; color: Theme.muted; font.pixelSize: 11 }
    }

    RowLayout {
        width: parent.width; spacing: 14

        // ================= left column =================
        Column {
            Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 12

            GridLayout {
                width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
                CcTile { icon: ""; title: "Night light"; sub: cc.night ? "On · 4500K" : "Off"; on: cc.night; accent: Theme.yellow
                       onHit: cc.run([cc.scripts + "/nightlight.sh"]) }
                CcTile { icon: ""; title: "Silent"; sub: Notifs.dnd ? "No pop-ups" : "Off"; on: Notifs.dnd; accent: Theme.purple
                       onHit: Notifs.dnd = !Notifs.dnd }
                CcTile { icon: ""; title: "Keep awake"; sub: cc.awake ? "No auto-lock" : "Off"; on: cc.awake; accent: Theme.cyan
                       onHit: cc.run([cc.scripts + "/idle-inhibit.sh"]) }
                CcTile { icon: ""; title: "Performance"; sub: cc.perf ? "Max power" : "Balanced"; on: cc.perf; accent: Theme.red
                       onHit: cc.run(["powerprofilesctl", "set", cc.perf ? "balanced" : "performance"]) }
            }

            CcCard {
                title: "Sound"; icon: ""
                RowLayout {
                    width: parent.width; spacing: 10
                    Label { text: cc.sink && cc.sink.audio && cc.sink.audio.muted ? "" : ""; color: Theme.green; Layout.preferredWidth: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted } }
                    Slider { Layout.fillWidth: true; accent: Theme.green; value: cc.sink && cc.sink.audio ? cc.sink.audio.volume : 0
                             onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } } }
                    Label { text: cc.sink && cc.sink.audio ? Math.round(cc.sink.audio.volume * 100) + "%" : ""; color: Theme.muted; font.pixelSize: 10; Layout.preferredWidth: 30 }
                }
                RowLayout {
                    width: parent.width; spacing: 10
                    Label { text: cc.source && cc.source.audio && cc.source.audio.muted ? "" : ""; color: Theme.purple; Layout.preferredWidth: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted } }
                    Slider { Layout.fillWidth: true; accent: Theme.purple; value: cc.source && cc.source.audio ? cc.source.audio.volume : 0
                             onMoved: v => { if (cc.source) cc.source.audio.volume = v } }
                    Label { text: cc.source && cc.source.audio ? Math.round(cc.source.audio.volume * 100) + "%" : ""; color: Theme.muted; font.pixelSize: 10; Layout.preferredWidth: 30 }
                }
                Flow {     // output device chips
                    width: parent.width; spacing: 6
                    Repeater {
                        model: cc.sinks
                        Rectangle {
                            required property var modelData
                            readonly property bool cur: cc.sink && cc.sink.id === modelData.id
                            width: dl.implicitWidth + 22; height: 26; radius: 13
                            color: cur ? Theme.blue : (dMouse.containsMouse ? "#33c0caf5" : "#661a1b26")
                            Label { id: dl; anchors.centerIn: parent; text: (modelData.nickname || modelData.description || modelData.name).slice(0, 22)
                                    color: cur ? Theme.bg : Theme.fgDim; font.pixelSize: 10 }
                            MouseArea { id: dMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                        }
                    }
                }
            }

            CcCard {
                visible: apps.apps.length > 0
                AppVolumes { id: apps }
            }
        }

        // ================= right column =================
        Column {
            Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 12

            CcCard {
                title: "System"; icon: ""
                RowLayout {
                    width: parent.width; spacing: 8
                    MiniStat { icon: ""; title: "CPU"; usage: Stats.d.cpu; temp: Stats.d.cpuTemp; extra: Stats.d.cpuFreq + " GHz"; accent: Theme.cyan }
                    MiniStat { icon: "\u{f08ae}"; title: "GPU"; usage: Stats.d.gpu; temp: Stats.d.gpuTemp; extra: Stats.d.gpuPower + " W"; accent: Theme.purple }
                    MiniStat { icon: ""; title: "RAM"; usage: Stats.d.ram; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB"; accent: Theme.yellow }
                }
                RowLayout {
                    width: parent.width
                    Label { text: "\u{f0318}  " + (Stats.d.iface || "network"); color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true }
                    Label { text: " " + cc.speed(Stats.d.netRx || 0); color: Theme.green; font.pixelSize: 10 }
                    Label { text: "   " + cc.speed(Stats.d.netTx || 0); color: Theme.purple; font.pixelSize: 10 }
                }
            }

            CcCard {
                title: Notifs.count > 0 ? "Notifications · " + Notifs.count : "Notifications"; icon: ""
                Label {
                    visible: Notifs.count === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up"; color: Theme.muted; font.pixelSize: 11
                    bottomPadding: 6
                }
                ListView {
                    visible: Notifs.count > 0
                    width: parent.width
                    height: Math.min(contentHeight, 230)
                    clip: true; spacing: 6
                    verticalLayoutDirection: ListView.BottomToTop
                    model: Notifs.model
                    delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                }
                Rectangle {
                    visible: Notifs.count > 0
                    width: parent.width; height: 26; radius: 8
                    color: clrMouse.containsMouse ? "#33c0caf5" : "#661a1b26"
                    Label { anchors.centerIn: parent; text: "Clear all"; color: Theme.fgDim; font.pixelSize: 10 }
                    MouseArea { id: clrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                }
            }

            CcCard {
                visible: SystemTray.items.values.length > 0 || Updates.total > 0
                RowLayout {
                    width: parent.width; spacing: 10
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 20; height: 20
                            IconImage { anchors.fill: parent; source: modelData.icon; opacity: trMouse.containsMouse ? 1 : 0.8 }
                            MouseArea {
                                id: trMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: m => {
                                    if (m.button === Qt.RightButton || modelData.onlyMenu) {
                                        const win = parent.QsWindow.window
                                        const p = mapToItem(win.contentItem, 0, height + 6)
                                        modelData.display(win, p.x, p.y)
                                    } else modelData.activate()
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: Updates.total > 0
                        width: ul.implicitWidth + 20; height: 26; radius: 13
                        color: uMouse.containsMouse ? "#8fb0ff" : Theme.blue
                        Label { id: ul; anchors.centerIn: parent; text: "  " + Updates.total + " updates"; color: Theme.bg; font.pixelSize: 10 }
                        MouseArea { id: uMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { cc.visible = false
                                Quickshell.execDetached(["kitty", "--class", "updater", "-e", "bash", "-c", "yay -Syu; echo; read -n1 -rsp 'Done – press any key to close'"]) } }
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 8
                Repeater {
                    model: [
                        ["", "Snip",      ["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"]],
                        ["", "Color",     ["sh", "-c", "sleep 0.3; hyprpicker -a"]],
                        ["", "Wallpaper", ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "wallpaper", "toggle"]],
                        ["", "Games",     ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "games", "toggle"]],
                        ["", "Settings",  ["systemsettings"]]
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 52; radius: 12
                        color: qMouse.containsMouse ? "#33c0caf5" : Theme.card
                        border.width: 1; border.color: "#14c0caf5"
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: Theme.blue; font.pixelSize: 14 }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: Theme.fgDim; font.pixelSize: 9; font.weight: Font.Normal }
                        }
                        MouseArea { id: qMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { cc.visible = false; Quickshell.execDetached(modelData[2]) } }
                    }
                }
            }
        }
    }
}
