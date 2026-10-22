// Home screen (SUPER + Esc): a full-screen view over the blurred wallpaper — giant clock and today's line,
// then cards for music, calendar, system, sound and notifications, and session buttons. Esc or click empty
// space closes it. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
    id: root
    required property var screen
    property bool visible: false
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { PopupState.current = root; month = new Date(); now = new Date() }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "home"; function toggle(): void { root.toggle() } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

    property date now: new Date()
    Timer { interval: 1000; running: root.visible; repeat: true; onTriggered: root.now = new Date() }
    property date month: new Date()
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    property string art: ""
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt
    Timer { running: root.visible && root.player && root.player.isPlaying; interval: 1000; repeat: true; onTriggered: root.player.positionChanged() }
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    function mmss(t) { t = Math.max(0, Math.floor(t || 0)); return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0") }
    function go(cmd) { root.visible = false; Quickshell.execDetached(cmd) }

    component Card: Rectangle {
        default property alias inner: body.data
        property string title: ""
        radius: 20; color: Theme.card; border.width: 1; border.color: Theme.stroke
        Text { visible: parent.title !== ""; x: 18; y: 14; text: parent.title.toUpperCase(); color: Theme.muted
               font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.4 }
        Item { id: body; anchors.fill: parent; anchors.margins: 18; anchors.topMargin: parent.title !== "" ? 38 : 18 }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-home"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "#000000"

        Image { id: bg; anchors.fill: parent; source: Settings.cur("wall_main") ? "file://" + Settings.cur("wall_main") : ""
                sourceSize.width: 1280; fillMode: Image.PreserveAspectCrop; visible: false; asynchronous: true }
        MultiEffect { anchors.fill: parent; source: bg; blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.38 }
        Rectangle { anchors.fill: parent; color: Theme.mix(Qt.rgba(0, 0, 0, 0.35), Theme.tint, 0.12 * Theme.tintOn) }
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
        Item { anchors.fill: parent; focus: root.visible; Keys.onEscapePressed: root.visible = false }

        // ---------- clock ----------
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.13; spacing: 8
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, Settings.cur("clock_12h") ? "h:mm" : "HH:mm")
                   color: "#f5f5f5"; font.family: Theme.font; font.pixelSize: 170; font.weight: Font.Thin }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.now, "dddd, d MMMM").toLowerCase()
                   color: "#b8b8b8"; font.family: Theme.font; font.pixelSize: 20; font.letterSpacing: 1 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Journey.today()
                   color: "#a0a0a0"; font.family: Theme.font; font.pixelSize: 14; font.italic: true }
        }

        // ---------- cards ----------
        RowLayout {
            id: cards
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.52
            spacing: 16
            height: 300

            // music
            Card {
                title: "now playing"
                Layout.preferredWidth: 360; Layout.fillHeight: true
                MouseArea { anchors.fill: parent }   // clicks here don't close the screen
                Column {
                    anchors.fill: parent; spacing: 12
                    Row {
                        spacing: 14
                        ClippingRectangle {
                            width: 96; height: 96; radius: 14; color: Theme.bgAlt
                            Image { anchors.fill: parent; source: root.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: root.art !== "" }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 4; width: 200
                            Text { width: parent.width; elide: Text.ElideRight; text: root.player ? root.player.trackTitle : "nothing playing"
                                   color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
                            Text { width: parent.width; elide: Text.ElideRight; text: root.player ? root.player.trackArtist : ""
                                   color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                        }
                    }
                    Item {
                        width: parent.width; height: 14; visible: !!(root.player && root.player.length > 0)
                        Text { id: hp; anchors.left: parent.left; text: root.player ? root.mmss(root.player.position) : ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        Text { id: hl; anchors.right: parent.right; text: root.player ? root.mmss(root.player.length) : ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        Rectangle {
                            anchors.left: hp.right; anchors.right: hl.left; anchors.margins: 10; anchors.verticalCenter: parent.verticalCenter
                            height: 4; radius: 2; color: "#26ffffff"
                            Rectangle { height: parent.height; radius: 2; color: Theme.on
                                        width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0 }
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                        Repeater {
                            model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                            Rectangle {
                                required property var modelData
                                readonly property bool main: modelData[1] === "toggle"
                                width: main ? 52 : 40; height: width; radius: width / 2
                                color: main ? Theme.on : (mm.containsMouse ? "#22ffffff" : "transparent")
                                Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 22 : 17; color: main ? Theme.onText : "#e0e0e0"
                                       text: main ? (root.player && root.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (!root.player) return; modelData[1] === "prev" ? root.player.previous() : modelData[1] === "next" ? root.player.next() : root.player.togglePlaying() } }
                            }
                        }
                    }
                }
            }

            // calendar
            Card {
                title: Qt.formatDate(root.month, "MMMM yyyy").toLowerCase()
                Layout.preferredWidth: 320; Layout.fillHeight: true
                MouseArea { anchors.fill: parent }
                Row {
                    anchors.right: parent.right; y: -28; spacing: 4
                    Repeater {
                        model: [["\u{f0141}", -1], ["\u{f0142}", 1]]
                        Rectangle {
                            required property var modelData
                            width: 24; height: 24; radius: 12; color: am.containsMouse ? "#22ffffff" : "transparent"
                            Text { anchors.centerIn: parent; text: modelData[0]; color: "#c8c8c8"; font.family: Theme.font; font.pixelSize: 13 }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const m = new Date(root.month); m.setMonth(m.getMonth() + modelData[1]); root.month = m } }
                        }
                    }
                }
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7; columnSpacing: 4; rowSpacing: 4
                    Repeater {
                        model: ["m", "t", "w", "t", "f", "s", "s"]
                        Text { required property string modelData; width: 36; height: 22; horizontalAlignment: Text.AlignHCenter
                               text: modelData; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    Repeater {
                        model: {
                            const y = root.month.getFullYear(), m = root.month.getMonth()
                            const first = (new Date(y, m, 1).getDay() + 6) % 7, days = new Date(y, m + 1, 0).getDate()
                            const out = []; for (let i = 0; i < first; i++) out.push(0)
                            for (let d = 1; d <= days; d++) out.push(d)
                            return out
                        }
                        Rectangle {
                            required property int modelData
                            readonly property bool today: modelData > 0 && modelData === root.now.getDate()
                                                          && root.month.getMonth() === root.now.getMonth() && root.month.getFullYear() === root.now.getFullYear()
                            width: 36; height: 30; radius: 15; color: today ? Theme.on : "transparent"
                            Text { anchors.centerIn: parent; visible: modelData > 0; text: modelData; font.family: Theme.font; font.pixelSize: 12
                                   color: today ? Theme.onText : "#d0d0d0"; font.bold: today }
                        }
                    }
                }
            }

            // system
            Card {
                title: "system"
                Layout.preferredWidth: 360; Layout.fillHeight: true
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors.fill: parent; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        MiniStat { title: "CPU"; usage: Stats.d.cpu; temp: Stats.d.cpuTemp; extra: Stats.d.cpuFreq + " GHz" }
                        MiniStat { title: "GPU"; usage: Stats.d.gpu; temp: Stats.d.gpuTemp; extra: Stats.d.gpuPower + " W" }
                        MiniStat { title: "RAM"; usage: Stats.d.ram; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB" }
                    }
                    Text { Layout.alignment: Qt.AlignHCenter; text: "up " + Stats.d.uptime + "   ·   vram " + (Stats.d.vramUsed || 0).toFixed(1) + " / " + (Stats.d.vramTotal || 0).toFixed(0) + " GB"
                           color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                }
            }

            // sound + notifications
            ColumnLayout {
                Layout.preferredWidth: 340; Layout.fillHeight: true; spacing: 16
                Card {
                    title: "sound"
                    Layout.fillWidth: true; Layout.preferredHeight: 100
                    MouseArea { anchors.fill: parent }
                    CcSlider {
                        width: parent.width
                        icon: "\u{f057e}"; text: "volume"
                        muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)
                        value: root.sink && root.sink.audio ? Math.min(1, root.sink.audio.volume) : 0
                        onMoved: v => { if (root.sink) { root.sink.audio.muted = false; root.sink.audio.volume = v } }
                        onIconClicked: if (root.sink) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
                Card {
                    title: "notifications" + (Notifs.count > 0 ? "  ·  " + Notifs.count : "")
                    Layout.fillWidth: true; Layout.fillHeight: true
                    MouseArea { anchors.fill: parent }
                    Text { visible: Notifs.count === 0; anchors.centerIn: parent; text: "all caught up"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    ListView {
                        visible: Notifs.count > 0; anchors.fill: parent; clip: true; spacing: 6
                        verticalLayoutDirection: ListView.BottomToTop; model: Notifs.model
                        delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                    }
                }
            }
        }

        // ---------- session ----------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: cards.y + cards.height + 50; spacing: 14
            Repeater {
                model: [["\u{f033e}", "lock", ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"]],
                        ["\u{f0904}", "sleep", ["systemctl", "suspend"]],
                        ["\u{f0343}", "log out", ["hyprctl", "dispatch", "hl.dsp.exit()"]],
                        ["\u{f0709}", "restart", ["systemctl", "reboot"]],
                        ["\u{f0425}", "shut down", ["systemctl", "poweroff"]]]
                Column {
                    required property var modelData
                    required property int index
                    spacing: 6
                    property bool armed: false
                    Timer { id: disarm; interval: 3000; onTriggered: parent.armed = false }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 50; height: 50; radius: 25
                        color: parent.armed ? Theme.red : (sb.containsMouse ? Theme.on : Theme.card)
                        border.width: 1; border.color: Theme.stroke
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: modelData[0]; font.family: Theme.font; font.pixelSize: 18
                               color: sb.containsMouse && !parent.parent.armed ? Theme.onText : "#e0e0e0" }
                        MouseArea { id: sb; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {   // log out / restart / shut down ask for a second click
                                if (index >= 2 && Settings.cur("confirm_power") && !parent.parent.armed) { parent.parent.armed = true; disarm.restart(); return }
                                root.go(modelData[2])
                            } }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.armed ? "again" : modelData[1]
                           color: parent.armed ? Theme.red : Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }
}
