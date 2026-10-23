// Control center (SUPER + A, or the sliders icon in the bar). One calm column under the right end of the bar:
//   you · quick toggles · sound / mic / brightness · now playing · notifications · shortcuts
// Solid dark surfaces, big touch-sized controls, white = on. Esc or click outside closes. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

Scope {
    id: cc
    required property var screen
    property bool visible: false
    property bool shown: false
    property bool soundMore: false
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    function toggle() { visible = !visible }
    onVisibleChanged: {
        if (visible) { shown = true; soundMore = false; PopupState.current = cc; SysState.refresh(); brGet.running = true }
        else hideLater.restart()
    }
    Timer { id: hideLater; interval: 240; onTriggered: if (!cc.visible) cc.shown = false }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== cc) cc.visible = false } }
    IpcHandler { target: "panel"; function toggle(): void { cc.toggle() } }

    // ---------- data ----------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].concat(cc.sinks) }
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify" && p.trackTitle) || null
    property string art: ""
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt
    Timer { running: cc.visible && cc.player && cc.player.isPlaying; interval: 1000; repeat: true; onTriggered: cc.player.positionChanged() }
    property var bright: ({ "DP-1": 100, "DP-2": 100 })
    property var brPending: ({})
    readonly property string brCmd: Qt.resolvedUrl("brightness.sh").toString().replace("file://", "")
    Process { id: brGet; command: [cc.brCmd, "get"]; stdout: StdioCollector { onStreamFinished: { try { cc.bright = JSON.parse(this.text) } catch (e) {} } } }
    Timer { id: brSet; interval: 250; onTriggered: { for (const k in cc.brPending) Quickshell.execDetached([cc.brCmd, "set", k, String(cc.brPending[k])]); cc.brPending = {} } }
    function setBright(v) {   // one slider drives both screens
        const b = Object.assign({}, bright), p = Object.assign({}, brPending)
        for (const k of ["DP-1", "DP-2"]) { b[k] = v; p[k] = v }
        bright = b; brPending = p; brSet.restart()
    }
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }

    // ---------- look ----------
    readonly property color s0: "#f00b0b0b"     // panel
    readonly property color s1: "#161616"       // raised surface
    readonly property color s2: "#222222"       // hover / track
    readonly property color hi: "#ececec"       // "on"
    readonly property color ink: "#0b0b0b"      // text on white
    readonly property color dim: "#8a8a8a"

    // ---------- building blocks ----------
    component Round: Rectangle {   // round icon button
        property string icon; property int size: 38; signal hit()
        width: size; height: size; radius: size / 2
        color: rm.containsMouse ? cc.hi : cc.s1
        Behavior on color { ColorAnimation { duration: 120 } }
        Text { anchors.centerIn: parent; text: parent.icon; color: rm.containsMouse ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 15 }
        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }
    component Tile: Rectangle {   // quick toggle
        id: t
        property string icon; property string name; property string info: ""; property bool on: false
        signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1; height: 82; radius: 20
        color: on ? cc.hi : (tm.containsMouse ? cc.s2 : cc.s1)
        Behavior on color { ColorAnimation { duration: 160 } }
        Rectangle {
            x: 12; y: 12; width: 30; height: 30; radius: 15
            color: t.on ? cc.ink : "#2a2a2a"
            Behavior on color { ColorAnimation { duration: 160 } }
            Text { anchors.centerIn: parent; text: t.icon; color: t.on ? "#ffffff" : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 14 }
        }
        Column {
            x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 11; width: parent.width - 24; spacing: 1
            Text { width: parent.width; elide: Text.ElideRight; text: t.name; color: t.on ? cc.ink : "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            Text { width: parent.width; elide: Text.ElideRight; text: t.info || (t.on ? "on" : "off"); color: t.on ? "#80000000" : "#707070"; font.family: Theme.font; font.pixelSize: 10 }
        }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.hit() }
    }
    component Big: Rectangle {   // big pill slider: the white fill carries the icon, like a phone
        id: bs
        property string icon; property string label; property real value: 0; property bool muted: false; property bool canMute: false
        signal moved(real v)
        signal iconHit()
        Layout.fillWidth: true; height: 48; radius: 24; color: cc.s1
        readonly property real f: muted ? 0 : Math.max(0, Math.min(1, value))
        readonly property real fillW: height + (width - height) * f
        Text { x: 48; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 120; elide: Text.ElideRight
               text: bs.label; color: "#e6e6e6"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
        Item {   // white fill with dark copies of the text, so it reads on both sides of the edge
            width: bs.fillW; height: parent.height; clip: true
            Behavior on width { enabled: !bm.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Rectangle { width: bs.fillW; height: bs.height; radius: 24; color: bs.muted ? "#3a3a3a" : cc.hi }
            Text { x: 17; anchors.verticalCenter: parent.verticalCenter; text: bs.icon; color: bs.muted ? "#bdbdbd" : cc.ink; font.family: Theme.font; font.pixelSize: 16 }
            Text { x: 48; anchors.verticalCenter: parent.verticalCenter; width: bs.width - 120; elide: Text.ElideRight
                   text: bs.label; color: cc.ink; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
               text: bs.muted ? "muted" : Math.round(bs.value * 100) + "%"
               color: bs.fillW > bs.width - 50 ? "#90000000" : cc.dim; font.family: Theme.font; font.pixelSize: 11 }
        MouseArea {
            id: bm; anchors.fill: parent; anchors.leftMargin: bs.canMute ? 46 : 0
            cursorShape: Qt.PointingHandCursor; preventStealing: true
            function set(mx) { bs.moved(Math.max(0, Math.min(1, (mx + anchors.leftMargin - bs.height / 2) / (bs.width - bs.height)))) }
            onPressed: m => set(m.x); onPositionChanged: m => { if (pressed) set(m.x) }
            onWheel: w => bs.moved(Math.max(0, Math.min(1, bs.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
        }
        MouseArea { visible: bs.canMute; width: 46; height: parent.height; cursorShape: Qt.PointingHandCursor; onClicked: bs.iconHit() }
    }
    component Choice: Flow {   // a row of pills, one picked
        id: ch
        property var options: []; property var current; signal picked(var v)
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: ch.options
            Rectangle {
                required property var modelData
                readonly property bool on: ch.current === modelData[0]
                width: cl.implicitWidth + 26; height: 32; radius: 16
                color: on ? cc.hi : (cm.containsMouse ? cc.s2 : cc.s1)
                Behavior on color { ColorAnimation { duration: 130 } }
                Text { id: cl; anchors.centerIn: parent; text: modelData[1]; color: on ? cc.ink : "#bdbdbd"; font.family: Theme.font; font.pixelSize: 11; font.bold: on }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ch.picked(modelData[0]) }
            }
        }
    }

    PanelWindow {
        visible: cc.shown; screen: cc.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-control"
        WlrLayershell.keyboardFocus: cc.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: cc.visible = false }

        Rectangle {
            id: panel
            width: 420
            x: parent.width - width - 10; y: Theme.barHeight + 16
            height: body.implicitHeight + 36
            radius: 28
            color: cc.s0
            border.width: 1; border.color: "#14ffffff"
            opacity: cc.visible ? 1 : 0
            transform: Translate { y: cc.visible ? 0 : -10; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false

            ColumnLayout {
                id: body
                x: 18; y: 18; width: parent.width - 36; spacing: 10

                // ---------- you ----------
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 6; spacing: 12
                    ClippingRectangle {
                        width: 44; height: 44; radius: 22; color: cc.s1
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 96; asynchronous: true
                                source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face" }
                    }
                    Column {
                        Layout.fillWidth: true; spacing: 3
                        Text { text: Settings.cur("user_name") || "yu"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                        Text { text: "up " + Stats.d.uptime; color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Round { icon: "\u{f0493}"; onHit: cc.qs("settings") }
                    Round { icon: "\u{f033e}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"]) }
                    Round { icon: "\u{f0425}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "bar", "power"]) }
                }

                // ---------- quick toggles ----------
                GridLayout {
                    Layout.fillWidth: true; columns: 3; rowSpacing: 10; columnSpacing: 10
                    Tile { icon: "\u{f009b}"; name: "silent"; on: Notifs.dnd; info: on ? "silenced" : "off"; onHit: Notifs.dnd = !Notifs.dnd }
                    Tile { icon: "\u{f0594}"; name: "night light"; on: SysState.night; info: on ? "warm" : "off"; onHit: SysState.toggleNight() }
                    Tile { icon: "\u{f0176}"; name: "keep awake"; on: SysState.awake; info: on ? "no auto-lock" : "off"; onHit: SysState.toggleAwake() }
                    Tile { icon: "\u{f04c5}"; name: "performance"; on: SysState.perf; info: on ? "max power" : "balanced"; onHit: SysState.setProfile(SysState.perf ? "balanced" : "performance") }
                    Tile { icon: "\u{f036c}"; name: "clean mic"; on: !!SysState.fx.mic; info: on ? "noise removed" : "off"; onHit: SysState.fxToggle("mic") }
                    Tile { icon: "\u{f0eb5}"; name: "game mode"; on: SysState.gameMode; info: on ? "on" : "auto"
                           onHit: { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode } }
                }

                // ---------- sliders ----------
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; spacing: 8
                    Big {
                        icon: muted ? "\u{f075f}" : "\u{f057e}"; label: cc.nice(cc.sink); canMute: true
                        muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                        value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                        onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                        onIconHit: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                    }
                    Rectangle {   // output + EQ
                        width: 48; height: 48; radius: 24
                        color: cc.soundMore ? cc.hi : (mm.containsMouse ? cc.s2 : cc.s1)
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Text { anchors.centerIn: parent; text: cc.soundMore ? "\u{f0143}" : "\u{f0140}"; color: cc.soundMore ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 16 }
                        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cc.soundMore = !cc.soundMore }
                    }
                }
                ColumnLayout {
                    visible: cc.soundMore
                    Layout.fillWidth: true; Layout.leftMargin: 4; Layout.bottomMargin: 4; spacing: 8
                    Text { visible: cc.sinks.length > 1; text: "output"; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 10 }
                    Choice {
                        visible: cc.sinks.length > 1
                        options: cc.sinks.map(n => [n.id, cc.nice(n)])
                        current: { const s = cc.sinks.find(n => cc.sink && (n.id === cc.sink.id || (cc.sink.name === "headset_eq" && (n.name || "").indexOf("Fuxi") >= 0))); return s ? s.id : -1 }
                        onPicked: v => { if (SysState.fx.eq) SysState.fxToggle("eq"); const n = cc.sinks.find(x => x.id === v); if (n) Pipewire.preferredDefaultAudioSink = n }
                    }
                    Text { text: "equalizer"; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 10 }
                    Choice {
                        options: [["off", "flat"], ["music", "music"], ["vocal", "vocal"], ["games", "games"], ["bass", "bass"]]
                        current: SysState.fx.eq ? SysState.fx.preset : "off"
                        onPicked: v => { if (v === "off") { if (SysState.fx.eq) SysState.fxToggle("eq"); return }
                                         if (!SysState.fx.eq) SysState.fxToggle("eq"); SysState.fxPreset(v) }
                    }
                }
                Big {
                    icon: muted ? "\u{f036d}" : "\u{f036c}"; label: "microphone"; canMute: true
                    muted: !!(cc.source && cc.source.audio && cc.source.audio.muted)
                    value: cc.source && cc.source.audio ? Math.min(1, cc.source.audio.volume) : 0
                    onMoved: v => { if (cc.source) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                    onIconHit: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted
                }
                Big { icon: "\u{f00e0}"; label: "brightness"; value: (cc.bright["DP-1"] || 0) / 100; onMoved: v => cc.setBright(Math.round(v * 100)) }

                // ---------- now playing ----------
                Rectangle {
                    visible: !!cc.player
                    Layout.fillWidth: true; Layout.topMargin: 4; height: 96; radius: 22; color: cc.s1
                    ClippingRectangle {
                        x: 12; y: 12; width: 72; height: 72; radius: 14; color: cc.s2
                        Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 160 }
                    }
                    Column {
                        x: 98; y: 16; width: parent.width - 98 - 14; spacing: 3
                        Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                        Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: cc.dim; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Item {   // progress
                        visible: !!(cc.player && cc.player.length > 0)
                        x: 98; y: 66; width: parent.width - 98 - 132; height: 12
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#2c2c2c" }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; height: 4; radius: 2; color: "#e6e6e6"
                                    width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0 }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                    onClicked: m => { if (cc.player && cc.player.canSeek) cc.player.position = (m.x / width) * cc.player.length } }
                    }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 12; y: 56; spacing: 2
                        Repeater {
                            model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                            Rectangle {
                                required property var modelData
                                readonly property bool main: modelData[1] === "toggle"
                                width: main ? 40 : 32; height: 32; radius: 16
                                color: main ? cc.hi : (pm.containsMouse ? cc.s2 : "transparent")
                                Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: 14; color: main ? cc.ink : "#e6e6e6"
                                       text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const p = cc.player; if (!p) return; modelData[1] === "prev" ? p.previous() : modelData[1] === "next" ? p.next() : p.togglePlaying() } }
                            }
                        }
                    }
                }

                // ---------- notifications ----------
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 6
                    Text { text: "notifications"; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                    Text { text: Notifs.count > 0 ? String(Notifs.count) : ""; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 11; Layout.fillWidth: true }
                    Text {
                        visible: Notifs.count > 0; text: "clear all"; color: clm.containsMouse ? "#ffffff" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 11
                        MouseArea { id: clm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                    }
                }
                Rectangle {
                    visible: Notifs.count === 0
                    Layout.fillWidth: true; height: 52; radius: 18; color: "transparent"; border.width: 1; border.color: "#1affffff"
                    Text { anchors.centerIn: parent; text: "nothing new"; color: "#5e5e5e"; font.family: Theme.font; font.pixelSize: 11 }
                }
                Repeater {
                    model: Notifs.model
                    NotifCard { required property var modelData; required property int index; visible: index < 3; notif: modelData; Layout.fillWidth: true }
                }

                // ---------- shortcuts ----------
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                    Repeater {
                        model: [["\u{f0100}", "screenshot", () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                                ["\u{f014c}", "clipboard", () => cc.qs("clipboard")],
                                ["\u{f02e9}", "wallpaper", () => cc.qs("wallpaper")],
                                ["\u{f082e}", "notes", () => cc.qs("notes")]]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredWidth: 1; height: 62; radius: 18
                            color: scm.containsMouse ? cc.hi : cc.s1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Column {
                                anchors.centerIn: parent; spacing: 6
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: scm.containsMouse ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 17 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: scm.containsMouse ? cc.ink : cc.dim; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            MouseArea { id: scm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
                        }
                    }
                }

                // ---------- tray + updates ----------
                RowLayout {
                    visible: SystemTray.items.values.length > 0 || Updates.total > 0
                    Layout.fillWidth: true; Layout.topMargin: 2; spacing: 14
                    Item { width: 4 }
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 16; height: 16
                            IconImage { id: trIcon; anchors.fill: parent; source: modelData.icon; visible: false }
                            MultiEffect { anchors.fill: trIcon; source: trIcon; saturation: -1.0; opacity: trM.containsMouse ? 1 : 0.5 }
                            MouseArea {
                                id: trM; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                        width: upl.implicitWidth + 28; height: 32; radius: 16
                        color: um.containsMouse ? cc.hi : cc.s1
                        Text { id: upl; anchors.centerIn: parent; text: "\u{f06b0}  " + Updates.total + " updates"; color: um.containsMouse ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 11 }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: cc.go(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                    }
                }
            }
        }
    }
}
