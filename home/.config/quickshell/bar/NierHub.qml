// Control hub (SUPER + A), NieR:Automata / Tsugumori style: numbered cards in a 3×3 cross around MENU.
// Arrows or H J K L move · Enter / Space does the card's main thing · scroll or − / + changes its value
// · MENU opens the full control center · Esc or click outside closes. Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
    id: root
    required property var screen
    property bool visible: false
    property int sel: 4                         // 0..8, 4 = MENU in the middle
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { sel = 4; PopupState.current = root; SysState.refresh(); brGet.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "hub"; function toggle(): void { root.toggle() } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    PwObjectTracker { objects: [Pipewire.defaultAudioSink].concat(root.sinks) }
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }

    // monitor brightness (DDC/CI), same helper as the control center
    property int bright: 100
    readonly property string brCmd: Qt.resolvedUrl("brightness.sh").toString().replace("file://", "")
    Process { id: brGet; command: [root.brCmd, "get"]; stdout: StdioCollector { onStreamFinished: { try { root.bright = JSON.parse(this.text)["DP-1"] || 100 } catch (e) {} } } }
    Timer { id: brSet; interval: 250; onTriggered: { Quickshell.execDetached([root.brCmd, "set", "DP-1", String(root.bright)]); Quickshell.execDetached([root.brCmd, "set", "DP-2", String(root.bright)]) } }

    function run(cmd) { Quickshell.execDetached(cmd) }
    function closeAnd(cmd) { visible = false; run(cmd) }
    // the nine cards: [number, title, japanese, body, left foot, right foot, action(), adjust(step)]
    readonly property var cards: [
        ["05", "media", "再生", player ? player.trackTitle : "nothing playing", player ? (player.trackArtist || "").slice(0, 18) : "", player && player.isPlaying ? "PLAYING" : "PAUSED",
         () => { if (player) player.togglePlaying() }, d => { if (player) d > 0 ? player.next() : player.previous() }],
        ["01", "connection", "接続", (Stats.d.iface || "offline") + " connected", "↓ " + speed(Stats.d.netRx || 0), "↑ " + speed(Stats.d.netTx || 0),
         () => closeAnd(["qs", "ipc", "-p", qsDir, "call", "settings", "open", "network"]), d => {}],
        ["06", "system", "系統", "cpu " + Stats.d.cpu + "%  ·  gpu " + Stats.d.gpu + "%", "RAM " + Stats.d.ram + "%", Stats.d.cpuTemp + "°C",
         () => closeAnd(["kitty", "--class", "btop", "-e", "btop"]), d => {}],
        ["02", "sound", "音響", nice(sink).slice(0, 24) || "no output", "VOL " + (sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0) + "%",
         sink && sink.audio && sink.audio.muted ? "MUTED" : "LIVE",
         () => { const i = sinks.findIndex(n => sink && (n.id === sink.id || (sink.name === "headset_eq" && (n.name || "").indexOf("Fuxi") >= 0)))
                 if (sinks.length > 1) { if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = sinks[(i + 1) % sinks.length] } },
         d => { if (sink && sink.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + d * 0.05)) } }],
        ["00", "menu", "制御", "control center", "ENTER", "OPEN",
         () => closeAnd(["qs", "ipc", "-p", qsDir, "call", "bar", "control"]), d => {}],
        ["03", "notifications", "通知", Notifs.count + " notification" + (Notifs.count === 1 ? "" : "s"), "HISTORY", Notifs.dnd ? "DND ON" : "DND OFF",
         () => { Notifs.dnd = !Notifs.dnd }, d => {}],
        ["07", "power", "電力", SysState.perf ? "max performance" : "balanced", SysState.gameMode ? "GAME ON" : "GAME AUTO", SysState.awake ? "AWAKE" : "AUTO-LOCK",
         () => SysState.setProfile(SysState.perf ? "balanced" : "performance"), d => {}],
        ["04", "display", "表示", "brightness " + bright + "%", SysState.night ? "NIGHT ON" : "NIGHT OFF", "DDC",
         () => SysState.toggleNight(), d => { bright = Math.max(0, Math.min(100, bright + d * 5)); brSet.restart() }],
        ["08", "session", "終了", "lock · sleep · power", "ENTER", "MENU",
         () => closeAnd(["qs", "ipc", "-p", qsDir, "call", "bar", "power"]), d => {}]
    ]
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }
    function act(i) { root.cards[i][6]() }
    function adjust(i, d) { root.cards[i][7](d) }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-control"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: Theme.mix(Qt.rgba(0, 0, 0, 0.62), Theme.tint, 0.08 * Theme.tintOn)
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }

        Item {
            anchors.fill: parent; focus: root.visible
            Keys.onPressed: e => {
                const k = e.key, r = Math.floor(root.sel / 3), c = root.sel % 3
                if (k === Qt.Key_Escape) root.visible = false
                else if (k === Qt.Key_Left || k === Qt.Key_H) root.sel = r * 3 + Math.max(0, c - 1)
                else if (k === Qt.Key_Right || k === Qt.Key_L) root.sel = r * 3 + Math.min(2, c + 1)
                else if (k === Qt.Key_Up || k === Qt.Key_K) root.sel = Math.max(0, r - 1) * 3 + c
                else if (k === Qt.Key_Down || k === Qt.Key_J) root.sel = Math.min(2, r + 1) * 3 + c
                else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.act(root.sel)
                else if (k === Qt.Key_Minus) root.adjust(root.sel, -1)
                else if (k === Qt.Key_Plus || k === Qt.Key_Equal) root.adjust(root.sel, 1)
                else return
                e.accepted = true
            }
        }

        // title strip
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: grid.y - 70; spacing: 12
            Text { text: "CONTROL"; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 13; font.letterSpacing: 4 }
            Text { text: "//"; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 13 }
            Text { text: "制御盤"; color: "#9a9a9a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 13 }
        }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: 3; spacing: 64
            Repeater {
                model: 9
                Item {
                    id: cell
                    required property int index
                    readonly property var d: root.cards[index]
                    readonly property bool cur: root.sel === index
                    readonly property bool axis: index % 2 === 1 || index === 4      // the cross (corners are a bit quieter)
                    width: 360; height: 128
                    opacity: axis || cur ? 1 : 0.82
                    scale: cur ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.fill: parent; radius: 2
                        color: Theme.mix(Qt.rgba(0.03, 0.03, 0.03, 0.88), Theme.tint, 0.08 * Theme.tintOn)
                        border.width: 1; border.color: cell.cur ? "#cfffffff" : "#33ffffff"
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                    }
                    // corner brackets
                    Repeater {
                        model: [[0, 0, 1, 1], [1, 0, -1, 1], [0, 1, 1, -1], [1, 1, -1, -1]]
                        Item {
                            required property var modelData
                            x: modelData[0] * (cell.width - 10) - (modelData[0] ? -4 : 4); y: modelData[1] * (cell.height - 10) - (modelData[1] ? -4 : 4)
                            width: 10; height: 10
                            Rectangle { x: modelData[2] > 0 ? 0 : 9; width: 1; height: 10; color: cell.cur ? "#ffffff" : "#55ffffff" }
                            Rectangle { y: modelData[3] > 0 ? 0 : 9; width: 10; height: 1; color: cell.cur ? "#ffffff" : "#55ffffff" }
                        }
                    }
                    // header bar: white when selected
                    Rectangle {
                        x: 1; y: 1; width: parent.width - 2; height: 30; radius: 1
                        color: cell.cur ? Theme.on : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; x: 12; spacing: 10
                            Text { text: cell.d[0]; color: cell.cur ? Theme.onText : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 11 }
                            Text { text: cell.d[1].toUpperCase(); color: cell.cur ? Theme.onText : "#e8e8e8"; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 2; font.bold: true }
                        }
                        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                               text: cell.d[2]; color: cell.cur ? "#55000000" : "#5a5a5a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 11 }
                    }
                    Rectangle { x: 1; y: 31; width: parent.width - 2; height: 1; color: "#22ffffff" }
                    Text {
                        x: 14; y: 44; width: parent.width - 28; elide: Text.ElideRight
                        text: cell.d[3]; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 15
                    }
                    Text { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; text: cell.d[4]; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                    Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                           text: cell.d[5]; color: cell.cur ? "#ffffff" : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = cell.index
                        onClicked: root.act(cell.index)
                        onWheel: w => root.adjust(cell.index, w.angleDelta.y > 0 ? 1 : -1)
                    }
                }
            }
        }
        // links along the cross (little connector marks between the centre and its four neighbours)
        Repeater {
            model: [[0, -1], [-1, 0], [1, 0], [0, 1]]
            Item {
                required property var modelData
                readonly property bool vert: modelData[0] === 0
                x: grid.x + grid.width / 2 + modelData[0] * (180 + 32) - width / 2
                y: grid.y + grid.height / 2 + modelData[1] * (64 + 32) - height / 2
                width: vert ? 14 : 40; height: vert ? 40 : 14
                Rectangle { anchors.centerIn: parent; width: parent.vert ? 1 : 40; height: parent.vert ? 40 : 1; color: "#44ffffff" }
                Rectangle { anchors.centerIn: parent; width: 7; height: 7; rotation: 45; color: "transparent"; border.width: 1; border.color: "#88ffffff" }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: grid.y + grid.height + 54
            text: "←↑↓→  move     enter  select     −  +  adjust     esc  close"
            color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1
        }
    }
}
