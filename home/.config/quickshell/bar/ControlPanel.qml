// Control center (SUPER + A, or the sliders icon in the bar), under the right end of the bar:
//   greeting · now playing · quick toggles
//   left:  sound (volume, mic, output, EQ) · screens        right: system rings + network · today (week, weather, timer)
//   notifications · shortcuts · tray + updates.   Esc or click outside closes. Made by Claude.
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
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    function toggle() { visible = !visible }
    onVisibleChanged: {
        if (visible) { shown = true; now = new Date(); PopupState.current = cc; SysState.refresh(); Battery.refresh(); brGet.running = true }
        else hideLater.restart()
    }
    Timer { id: hideLater; interval: 220; onTriggered: if (!cc.visible) cc.shown = false }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== cc) cc.visible = false } }
    IpcHandler { target: "panel"; function toggle(): void { cc.toggle() } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

    // ---------- data ----------
    property date now: new Date()
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].concat(cc.sinks) }
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify" && p.trackTitle) || null
    property string art: ""   // keep the last picture while a new track loads
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt
    Timer { running: cc.visible && cc.player && cc.player.isPlaying; interval: 1000; repeat: true; onTriggered: cc.player.positionChanged() }
    property var bright: ({ "DP-1": 100, "DP-2": 100 })
    property var brPending: ({})
    readonly property string brCmd: Qt.resolvedUrl("brightness.sh").toString().replace("file://", "")
    Process { id: brGet; command: [cc.brCmd, "get"]; stdout: StdioCollector { onStreamFinished: { try { cc.bright = JSON.parse(this.text) } catch (e) {} } } }
    Timer { id: brSet; interval: 250; onTriggered: { for (const k in cc.brPending) Quickshell.execDetached([cc.brCmd, "set", k, String(cc.brPending[k])]); cc.brPending = {} } }
    function setBright(mon, v) { const b = Object.assign({}, bright); b[mon] = v; bright = b; const p = Object.assign({}, brPending); p[mon] = v; brPending = p; brSet.restart() }
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }
    function mmss(t) { t = Math.max(0, Math.floor(t || 0)); return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0") }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }
    readonly property string greeting: {
        const h = now.getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }

    // ---------- look ----------
    readonly property color card: "#121212"
    readonly property color cardHi: "#1a1a1a"
    readonly property color line: "#1cffffff"
    readonly property color hi: "#ececec"
    readonly property color ink: "#0b0b0b"
    readonly property color dim: "#7a7a7a"

    // ---------- building blocks ----------
    component Card: Rectangle {   // a titled block: ICON  TITLE ··········· note
        default property alias inner: body.data
        property string title: ""; property string icon: ""; property string note: ""
        Layout.fillWidth: true
        implicitHeight: !title ? body.implicitHeight + 28 : body.implicitHeight > 0 ? body.implicitHeight + 52 : 42
        radius: 10; color: cc.card; border.width: 1; border.color: cc.line
        Row {
            visible: parent.title !== ""; x: 14; y: 14; spacing: 8
            Text { text: parent.parent.icon; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 12 }
            Text { text: parent.parent.title.toUpperCase(); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.6; font.bold: true }
        }
        Text { visible: parent.note !== ""; anchors.right: parent.right; anchors.rightMargin: 14; y: 14; text: parent.note; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
        Column { id: body; x: 14; y: parent.title ? 40 : 14; width: parent.width - 28; spacing: 10 }
    }
    component Seg: Rectangle {   // segmented choice, white pill = picked
        id: sg
        property var options: []; property var current; signal picked(var v)
        width: parent ? parent.width : 300; height: 32; radius: 8; color: "#0b0b0b"; border.width: 1; border.color: cc.line
        Row {
            anchors.fill: parent; anchors.margins: 3
            Repeater {
                model: sg.options
                Rectangle {
                    required property var modelData
                    readonly property bool on: sg.current === modelData[0]
                    width: parent.width / sg.options.length; height: parent.height; radius: 6
                    color: on ? cc.hi : (sgm.containsMouse ? "#1affffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; width: parent.width - 10; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                           text: modelData[1]; color: on ? cc.ink : "#a8a8a8"; font.family: Theme.font; font.pixelSize: 11; font.bold: on }
                    MouseArea { id: sgm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sg.picked(modelData[0]) }
                }
            }
        }
    }
    component Btn: Rectangle {   // small outlined button, white on hover
        property string text; signal hit()
        width: Math.max(38, bl.implicitWidth + 20); height: 28; radius: 7
        color: bm.containsMouse ? cc.hi : "transparent"; border.width: 1; border.color: bm.containsMouse ? cc.hi : "#2affffff"
        Behavior on color { ColorAnimation { duration: 110 } }
        Text { id: bl; anchors.centerIn: parent; text: parent.text; color: bm.containsMouse ? cc.ink : "#c8c8c8"; font.family: Theme.font; font.pixelSize: 11 }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
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
            width: 760
            x: parent.width - width - 10; y: Theme.barHeight + 16
            height: body.implicitHeight + 36
            radius: 14
            color: "#f20c0c0c"
            border.width: 1; border.color: "#24ffffff"
            opacity: cc.visible ? 1 : 0
            transform: Translate { y: cc.visible ? 0 : -8; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 160 } }
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false

            ColumnLayout {
                id: body
                x: 18; y: 18; width: parent.width - 36; spacing: 12

                // ================= greeting =================
                RowLayout {
                    Layout.fillWidth: true; spacing: 14
                    ClippingRectangle {
                        width: 46; height: 46; radius: 23; color: cc.card
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 96; asynchronous: true
                                source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face" }
                    }
                    Column {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: cc.greeting + ", " + (Settings.cur("user_name") || "yu"); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
                        Text {
                            text: Qt.formatDate(cc.now, "dddd d MMMM") + "   ·   up " + Stats.d.uptime
                                  + (Battery.known ? "   ·   " + Battery.icon + " " + Battery.percent + "%" + (Battery.charging ? " charging" : "") : "")
                            color: cc.dim; font.family: Theme.font; font.pixelSize: 11
                        }
                    }
                    Repeater {
                        model: [["\u{f0493}", () => cc.qs("settings")],
                                ["\u{f033e}", () => cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"])],
                                ["\u{f0425}", () => cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "bar", "power"])]]
                        Rectangle {
                            required property var modelData
                            width: 38; height: 38; radius: 19
                            color: hm.containsMouse ? cc.hi : cc.card; border.width: 1; border.color: hm.containsMouse ? cc.hi : cc.line
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: modelData[0]; color: hm.containsMouse ? cc.ink : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 15 }
                            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                        }
                    }
                }

                // ================= now playing (only while there's a track) =================
                ClippingRectangle {
                    visible: !!(cc.player && cc.player.trackTitle)
                    Layout.fillWidth: true; height: 104; radius: 10; color: cc.card
                    border.width: 1; border.color: cc.line
                    Image { id: artBg; anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false; sourceSize.width: 300 }
                    MultiEffect {   // the cover, blurred and greyed, as a backdrop
                        anchors.fill: parent; source: artBg; visible: cc.art !== ""
                        blurEnabled: true; blur: 1.0; blurMax: 64; saturation: -1.0; brightness: -0.3; opacity: 0.6
                    }
                    Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#c0080808" } GradientStop { position: 1; color: "#50080808" } } }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 16
                        ClippingRectangle {
                            width: 76; height: 76; radius: 8; color: cc.cardHi
                            Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 160 }
                        }
                        Column {
                            Layout.fillWidth: true; spacing: 3
                            Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                            Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 11 }
                            Item { width: 1; height: 8 }
                            Item {
                                visible: !!(cc.player && cc.player.length > 0)
                                width: parent.width; height: 14
                                Text { id: tpos; anchors.verticalCenter: parent.verticalCenter; text: cc.player ? cc.mmss(cc.player.position) : ""; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                Text { id: tlen; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: cc.player ? cc.mmss(cc.player.length) : ""; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                Rectangle {
                                    anchors.left: tpos.right; anchors.right: tlen.left; anchors.margins: 10; anchors.verticalCenter: parent.verticalCenter
                                    height: 4; radius: 2; color: "#33ffffff"
                                    Rectangle { height: 4; radius: 2; color: cc.hi
                                                width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0 }
                                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                                onClicked: m => { if (cc.player && cc.player.canSeek) cc.player.position = (m.x / width) * cc.player.length } }
                                }
                            }
                        }
                        Row {
                            spacing: 6
                            Repeater {
                                model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool main: modelData[1] === "toggle"
                                    width: main ? 46 : 34; height: width; radius: width / 2; anchors.verticalCenter: parent.verticalCenter
                                    color: main ? (pm.containsMouse ? "#ffffff" : cc.hi) : (pm.containsMouse ? "#26ffffff" : "transparent")
                                    Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 19 : 15; color: main ? cc.ink : "#e6e6e6"
                                           text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { const p = cc.player; if (!p) return; modelData[1] === "prev" ? p.previous() : modelData[1] === "next" ? p.next() : p.togglePlaying() } }
                                }
                            }
                        }
                    }
                }

                // ================= quick toggles (solid white when on) =================
                GridLayout {
                    Layout.fillWidth: true; columns: 3; rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: [
                            ["\u{f0594}", "Night light", SysState.night ? "Warm screen" : "Off", SysState.night, () => SysState.toggleNight()],
                            ["\u{f009b}", "Silent", Notifs.dnd ? "No pop-ups" : "Off", Notifs.dnd, () => { Notifs.dnd = !Notifs.dnd }],
                            ["\u{f0176}", "Keep awake", SysState.awake ? "No auto-lock" : "Off", SysState.awake, () => SysState.toggleAwake()],
                            ["\u{f04c5}", "Performance", SysState.perf ? "Max power" : "Balanced", SysState.perf, () => SysState.setProfile(SysState.perf ? "balanced" : "performance")],
                            ["\u{f036c}", "Clean mic", SysState.fx.mic ? "Noise removed" : "Off", !!SysState.fx.mic, () => SysState.fxToggle("mic")],
                            ["\u{f0eb5}", "Game mode", SysState.gameMode ? "On" : "Auto", SysState.gameMode,
                             () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode }]
                        ]
                        Rectangle {
                            id: tile
                            required property var modelData
                            readonly property bool on: modelData[3]
                            Layout.fillWidth: true; Layout.preferredWidth: 1; height: 58; radius: 10
                            color: on ? (tm.containsMouse ? "#ffffff" : cc.hi) : (tm.containsMouse ? cc.cardHi : cc.card)
                            border.width: 1; border.color: on ? "transparent" : cc.line
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                id: tic; x: 9; anchors.verticalCenter: parent.verticalCenter
                                width: 40; height: 40; radius: 20
                                color: tile.on ? "#1f000000" : "#12ffffff"
                                Text { anchors.centerIn: parent; text: tile.modelData[0]; color: tile.on ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 16 }
                            }
                            Column {
                                anchors.left: tic.right; anchors.leftMargin: 11; anchors.right: parent.right; anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Text { width: parent.width; elide: Text.ElideRight; text: tile.modelData[1]; color: tile.on ? cc.ink : "#f0f0f0"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                                Text { width: parent.width; elide: Text.ElideRight; text: tile.modelData[2]; color: tile.on ? "#90000000" : cc.dim; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.modelData[4]() }
                        }
                    }
                }

                // ================= two columns =================
                RowLayout {
                    Layout.fillWidth: true; spacing: 10

                    ColumnLayout {   // ---------- left ----------
                        Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.fillHeight: true; Layout.alignment: Qt.AlignTop; spacing: 10

                        Card {
                            title: "Sound"; icon: "\u{f057e}"
                            note: SysState.fx.eq ? "eq · " + SysState.fx.preset : ""
                            CcSlider {
                                icon: muted ? "\u{f075f}" : "\u{f057e}"; text: cc.nice(cc.sink).slice(0, 22)
                                muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                                value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                                onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                                onIconClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                            }
                            CcSlider {
                                icon: muted ? "\u{f036d}" : "\u{f036c}"; text: "Microphone"
                                muted: !!(cc.source && cc.source.audio && cc.source.audio.muted)
                                value: cc.source && cc.source.audio ? Math.min(1, cc.source.audio.volume) : 0
                                onMoved: v => { if (cc.source) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                                onIconClicked: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted
                            }
                            Seg {
                                visible: cc.sinks.length > 1
                                options: cc.sinks.map(n => [n.id, cc.nice(n)])
                                current: { const s = cc.sinks.find(n => cc.sink && (n.id === cc.sink.id || (cc.sink.name === "headset_eq" && (n.name || "").indexOf("Fuxi") >= 0))); return s ? s.id : -1 }
                                onPicked: v => { if (SysState.fx.eq) SysState.fxToggle("eq"); const n = cc.sinks.find(x => x.id === v); if (n) Pipewire.preferredDefaultAudioSink = n }
                            }
                            Seg {
                                options: [["off", "EQ off"], ["music", "Music"], ["vocal", "Vocal"], ["games", "Games"], ["bass", "Bass"]]
                                current: SysState.fx.eq ? SysState.fx.preset : "off"
                                onPicked: v => { if (v === "off") { if (SysState.fx.eq) SysState.fxToggle("eq"); return }
                                                 if (!SysState.fx.eq) SysState.fxToggle("eq"); SysState.fxPreset(v) }
                            }
                            Column {   // every app that's making sound, with its own volume
                                visible: Streams.apps.length > 0
                                width: parent.width; spacing: 8; topPadding: 2
                                Rectangle { width: parent.width; height: 1; color: cc.line }
                                Repeater {
                                    model: Streams.apps
                                    RowLayout {
                                        id: av
                                        required property var modelData
                                        readonly property bool muted: Streams.appMuted(modelData)
                                        width: parent.width; height: 26; spacing: 10
                                        Item {
                                            width: 18; height: 18
                                            IconImage { id: avIcon; anchors.fill: parent; visible: false
                                                        source: Quickshell.iconPath(av.modelData.icon, true) || Quickshell.iconPath("audio-x-generic") }
                                            MultiEffect { anchors.fill: avIcon; source: avIcon; saturation: -1.0; opacity: av.muted ? 0.35 : 0.9 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Streams.toggleAppMute(av.modelData) }
                                        }
                                        Text { Layout.preferredWidth: 78; elide: Text.ElideRight; text: av.modelData.name; color: av.muted ? "#5a5a5a" : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 11 }
                                        Slider { Layout.fillWidth: true; value: av.muted ? 0 : Math.min(1, Streams.appVolume(av.modelData)); onMoved: v => Streams.setAppVolume(av.modelData, v) }
                                        Text { Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight; text: av.muted ? "off" : Math.round(Streams.appVolume(av.modelData) * 100) + "%"
                                               color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }

                        Card {   // stretches so both columns end together
                            Layout.fillHeight: true
                            title: "Screens"; icon: "\u{f0379}"
                            Repeater {
                                model: [["DP-1", "Main"], ["DP-2", "Side"]]
                                CcSlider {
                                    required property var modelData
                                    icon: "\u{f00df}"; text: modelData[1]
                                    value: (cc.bright[modelData[0]] || 0) / 100
                                    onMoved: v => cc.setBright(modelData[0], Math.round(v * 100))
                                }
                            }
                        }

                    }

                    ColumnLayout {   // ---------- right ----------
                        Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.fillHeight: true; Layout.alignment: Qt.AlignTop; spacing: 10

                        Card {
                            title: "System"; icon: "\u{f04bc}"
                            note: "\u{f0045} " + cc.speed(Stats.d.netRx || 0) + "    \u{f005d} " + cc.speed(Stats.d.netTx || 0)
                            RowLayout {
                                width: parent.width; spacing: 0
                                MiniStat { title: "CPU"; usage: Stats.d.cpu; temp: Stats.d.cpuTemp; extra: Stats.d.cpuFreq + " GHz" }
                                MiniStat { title: "GPU"; usage: Stats.d.gpu; temp: Stats.d.gpuTemp; extra: Stats.d.gpuPower + " W" }
                                MiniStat { title: "RAM"; usage: Stats.d.ram; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB" }
                                MiniStat { title: "VRAM"; usage: Stats.d.vramTotal > 0 ? Math.round(100 * Stats.d.vramUsed / Stats.d.vramTotal) : 0
                                           extra: Stats.d.vramUsed.toFixed(1) + " / " + Stats.d.vramTotal.toFixed(0) + " GB" }
                            }
                        }

                        Card {
                            Layout.fillHeight: true
                            title: "Today"; icon: "\u{f00ed}"
                            note: Weather.ready ? Weather.place : ""
                            Row {   // this week, today in white
                                width: parent.width; spacing: 4
                                Repeater {
                                    model: 7
                                    Rectangle {
                                        required property int index
                                        readonly property date day: { const d = new Date(cc.now); d.setDate(d.getDate() - ((d.getDay() + 6) % 7) + index); return d }
                                        readonly property bool today: day.toDateString() === cc.now.toDateString()
                                        width: (parent.width - 24) / 7; height: 46; radius: 8
                                        color: today ? cc.hi : "transparent"; border.width: 1; border.color: today ? cc.hi : cc.line
                                        Column {
                                            anchors.centerIn: parent; spacing: 1
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(day, "ddd"); color: today ? "#90000000" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: day.getDate(); color: today ? cc.ink : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                visible: Weather.ready
                                width: parent.width; spacing: 12
                                Text { text: Weather.icon; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 30 }
                                Column {
                                    spacing: 1
                                    Text { text: Weather.temp + "°"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 22; font.bold: true }
                                    Text { text: Weather.desc + " · feels " + Weather.feels + "°"; color: cc.dim; font.family: Theme.font; font.pixelSize: 10 }
                                }
                                Item { Layout.fillWidth: true }
                                Repeater {
                                    model: Weather.days.slice(1, 3)
                                    Column {
                                        required property var modelData
                                        spacing: 2
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(modelData.date), "ddd"); color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: "#e0e0e0"; font.family: Theme.font; font.pixelSize: 15 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.max + "° " + modelData.min + "°"; color: "#a0a0a0"; font.family: Theme.font; font.pixelSize: 9 }
                                    }
                                }
                            }
                            Rectangle { width: parent.width; height: 1; color: cc.line }
                            RowLayout {   // quick timer: pick a length, or watch it count down
                                width: parent.width; spacing: 6
                                Text {
                                    Layout.fillWidth: true
                                    text: Timers.timerActive ? "\u{f051f}  " + Timers.fmt(Timers.remaining) : "\u{f051f}  Timer"
                                    color: Timers.timerRunning ? "#ffffff" : "#b0b0b0"; font.family: Theme.font
                                    font.pixelSize: Timers.timerActive ? 15 : 12; font.bold: Timers.timerActive
                                }
                                Repeater {
                                    model: Timers.timerActive ? [[Timers.timerRunning ? "\u{f03e4}" : "\u{f040a}", () => Timers.toggleTimer()], ["\u{f0450}", () => Timers.resetTimer()]]
                                                              : [["5m", () => { Timers.setMinutes(5); Timers.toggleTimer() }], ["15m", () => { Timers.setMinutes(15); Timers.toggleTimer() }],
                                                                 ["25m", () => { Timers.setMinutes(25); Timers.toggleTimer() }], ["1h", () => { Timers.setMinutes(60); Timers.toggleTimer() }]]
                                    Btn { required property var modelData; text: modelData[0]; onHit: modelData[1]() }
                                }
                            }
                        }
                    }
                }

                // ================= notifications =================
                Card {
                    title: "Notifications"; icon: "\u{f009a}"
                    note: Notifs.count > 0 ? Notifs.count + " new" : "all caught up"
                    ListView {
                        visible: Notifs.count > 0
                        width: parent.width; height: Math.min(contentHeight, 230)
                        clip: true; spacing: 6; boundsBehavior: Flickable.StopAtBounds
                        model: Notifs.model
                        delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                    }
                    Btn { visible: Notifs.count > 0; text: "Clear all"; onHit: Notifs.clearAll() }
                }

                // ================= shortcuts =================
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Repeater {
                        model: [
                            ["\u{f0100}", "Snip",      () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                            ["\u{f0d52}", "Color",     () => cc.go(["sh", "-c", "sleep 0.3; hyprpicker -a"])],
                            ["\u{f014c}", "Clipboard", () => cc.qs("clipboard")],
                            ["\u{f0785}", "Emoji",     () => cc.qs("emoji")],
                            ["\u{f02e9}", "Wallpaper", () => cc.qs("wallpaper")],
                            ["\u{f082e}", "Notes",     () => cc.qs("notes")],
                            ["\u{f0eb5}", "Games",     () => cc.qs("games")],
                            ["\u{f0349}", "Apps",      () => cc.qs("launcher")]
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredWidth: 1; height: 56; radius: 10
                            color: qm.containsMouse ? cc.hi : cc.card; border.width: 1; border.color: qm.containsMouse ? cc.hi : cc.line
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Column {
                                anchors.centerIn: parent; spacing: 5
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: qm.containsMouse ? cc.ink : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 17 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: qm.containsMouse ? cc.ink : cc.dim; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
                        }
                    }
                }

                // ================= tray + updates =================
                RowLayout {
                    visible: SystemTray.items.values.length > 0 || Updates.total > 0
                    Layout.fillWidth: true; spacing: 16
                    Item { width: 2 }
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 17; height: 17
                            IconImage { id: trIcon; anchors.fill: parent; source: modelData.icon; visible: false }
                            MultiEffect { anchors.fill: trIcon; source: trIcon; saturation: -1.0; opacity: trM.containsMouse ? 1 : 0.6 }
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
                        width: upl.implicitWidth + 26; height: 32; radius: 8
                        color: um.containsMouse ? "#ffffff" : cc.hi
                        Text { id: upl; anchors.centerIn: parent; text: "\u{f06b0}  Update " + Updates.total; color: cc.ink; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: cc.go(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                    }
                }
            }
        }
    }
}
