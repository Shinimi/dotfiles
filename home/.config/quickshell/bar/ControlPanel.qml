// Control center (SUPER + A, or the sliders icon in the bar): a full-height panel that slides in from the right,
// in numbered sections — now playing, quick toggles, sound, screens, system, notifications — with shortcuts and
// the tray at the bottom. Esc or click outside closes. Made by Claude.
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
        if (visible) { shown = true; PopupState.current = cc; SysState.refresh(); brGet.running = true }
        else hideLater.restart()
    }
    Timer { id: hideLater; interval: 300; onTriggered: if (!cc.visible) cc.shown = false }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== cc) cc.visible = false } }
    IpcHandler { target: "panel"; function toggle(): void { cc.toggle() } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

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
    function setBright(mon, v) { const b = Object.assign({}, bright); b[mon] = v; bright = b; const p = Object.assign({}, brPending); p[mon] = v; brPending = p; brSet.restart() }
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }
    function mmss(t) { t = Math.max(0, Math.floor(t || 0)); return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0") }
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }
    readonly property string greeting: {
        Stats.d.uptime
        const h = new Date().getHours()
        return h < 5 ? "good night" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : "good evening"
    }

    // ---------- building blocks ----------
    component Head: Item {   // 01 // TITLE ······ 日本語
        property string num; property string title; property string jp; property string note: ""
        width: parent ? parent.width : 400; height: 30
        Row {
            anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Text { text: parent.parent.num; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
            Text { text: "//"; color: "#3a3a3a"; font.family: Theme.font; font.pixelSize: 10 }
            Text { text: parent.parent.title; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2.5; font.bold: true }
            Text { text: parent.parent.note; visible: text !== ""; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10; leftPadding: 6 }
        }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: parent.jp; color: "#5a5a5a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 11 }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1fffffff" }
    }
    component Seg: Rectangle {   // segmented switch: options [[value, text]], current
        id: seg
        property var options: []; property var current; signal picked(var v)
        width: parent ? parent.width : 300; height: 30; radius: 2; color: "transparent"; border.width: 1; border.color: "#26ffffff"
        Row {
            anchors.fill: parent; anchors.margins: 2
            Repeater {
                model: seg.options
                Rectangle {
                    required property var modelData
                    readonly property bool on: seg.current === modelData[0]
                    width: parent.width / seg.options.length; height: parent.height; radius: 1
                    color: on ? Theme.on : (sm.containsMouse ? "#12ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; width: parent.width - 10; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                           text: modelData[1].toUpperCase(); color: on ? Theme.onText : "#a0a0a0"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.2; font.bold: on }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(modelData[0]) }
                }
            }
        }
    }
    component Bar: Item {   // CPU ━━━━━━━──── 12%  40°
        property string label; property real value: 0; property string val: ""; property string extra: ""
        width: parent ? parent.width : 300; height: 22
        Text { id: bl; width: 44; anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.5 }
        Rectangle {
            anchors.left: bl.right; anchors.right: br.left; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            height: 3; color: "#1fffffff"
            Rectangle { height: parent.height; width: parent.width * Math.min(1, Math.max(0, parent.parent.value)); color: parent.parent.value > 0.9 ? Theme.red : "#f0f0f0"
                        Behavior on width { NumberAnimation { duration: 300 } } }
        }
        Row {
            id: br; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Text { text: parent.parent.val; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 11; width: 40; horizontalAlignment: Text.AlignRight }
            Text { text: parent.parent.extra; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10; width: 74; horizontalAlignment: Text.AlignRight }
        }
    }
    component IconBtn: Rectangle {
        property string icon; signal hit()
        width: 34; height: 34; radius: 2
        color: ib.containsMouse ? Theme.on : "transparent"; border.width: 1; border.color: ib.containsMouse ? Theme.on : "#33ffffff"
        Behavior on color { ColorAnimation { duration: 110 } }
        Text { anchors.centerIn: parent; text: parent.icon; color: ib.containsMouse ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 15 }
        MouseArea { id: ib; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
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
            width: 480
            y: Theme.barHeight + 16; height: parent.height - y - 12
            x: cc.visible ? parent.width - width - 10 : parent.width + 24
            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            radius: 3; color: Theme.mix(Qt.rgba(0.03, 0.03, 0.03, 0.95), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1; border.color: "#3dffffff"
            Brackets {}
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false

            // ---------- header ----------
            RowLayout {
                id: header
                x: 18; y: 16; width: parent.width - 36; spacing: 12
                Avatar { size: 42 }
                Column {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: (Settings.cur("user_name") || "yu").toUpperCase(); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 15; font.letterSpacing: 3; font.bold: true }
                    Text { text: cc.greeting + "  ·  up " + Stats.d.uptime; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                }
                IconBtn { icon: "\u{f0493}"; onHit: cc.qs("settings") }
                IconBtn { icon: "\u{f033e}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"]) }
                IconBtn { icon: "\u{f0425}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "bar", "power"]) }
            }
            Rectangle { x: 1; y: header.y + header.height + 14; width: parent.width - 2; height: 1; color: "#26ffffff" }

            Flickable {
                id: flick
                x: 18; y: header.y + header.height + 22; width: parent.width - 36; height: foot.y - y - 8
                contentHeight: body.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: body
                    width: flick.width; spacing: 12

                    // ===== 01 now playing =====
                    Head { num: "01"; title: "NOW PLAYING"; jp: "再生"; note: cc.player ? (cc.player.isPlaying ? "▸ playing" : "paused") : "" }
                    Item {
                        width: parent.width; height: cc.player ? 186 : 44
                        Text { visible: !cc.player; anchors.centerIn: parent; text: "nothing playing"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11 }
                        ClippingRectangle {
                            id: cover
                            visible: !!cc.player
                            width: parent.width; height: 132; radius: 2; color: "#111111"
                            border.width: 1; border.color: "#1fffffff"
                            Image { id: coverImg; anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false; sourceSize.width: 900 }
                            MultiEffect { anchors.fill: parent; source: coverImg; blurEnabled: true; blur: 0.7; blurMax: 48; brightness: -0.35; saturation: -0.3 }
                            ClippingRectangle {
                                x: 14; anchors.verticalCenter: parent.verticalCenter; width: 104; height: 104; radius: 2; color: "#1a1a1a"
                                Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 260 }
                            }
                            Column {
                                x: 134; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 150; spacing: 4
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: "#c0c0c0"; font.family: Theme.font; font.pixelSize: 11 }
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackAlbum || "") : ""; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; topPadding: 2 }
                            }
                        }
                        Item {   // progress
                            visible: !!(cc.player && cc.player.length > 0)
                            y: cover.height + 12; width: parent.width; height: 14
                            Text { id: tp; text: cc.player ? cc.mmss(cc.player.position) : ""; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text { id: tl; anchors.right: parent.right; text: cc.player ? cc.mmss(cc.player.length) : ""; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                anchors.left: tp.right; anchors.right: tl.left; anchors.margins: 10; anchors.verticalCenter: parent.verticalCenter; height: 3; color: "#1fffffff"
                                Rectangle { height: parent.height; color: "#f0f0f0"; width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0 }
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                            onClicked: m => { if (cc.player && cc.player.canSeek) cc.player.position = (m.x / width) * cc.player.length } }
                            }
                        }
                        Row {   // controls
                            visible: !!cc.player
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; spacing: 8
                            Repeater {
                                model: [["\u{f049d}", "shuffle"], ["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"], ["\u{f0456}", "loop"]]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool main: modelData[1] === "toggle"
                                    readonly property bool lit: (modelData[1] === "shuffle" && cc.player && cc.player.shuffle) || (modelData[1] === "loop" && cc.player && cc.player.loopState !== MprisLoopState.None)
                                    width: main ? 44 : 32; height: main ? 30 : 30; radius: 2
                                    color: main ? (pm.containsMouse ? "#ffffff" : Theme.on) : (pm.containsMouse ? "#1affffff" : "transparent")
                                    border.width: main ? 0 : 1; border.color: lit ? "#99ffffff" : "#26ffffff"
                                    Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 16 : 13
                                           color: main ? Theme.onText : (parent.lit ? "#ffffff" : "#9a9a9a")
                                           text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { const p = cc.player; if (!p) return
                                            if (modelData[1] === "prev") p.previous(); else if (modelData[1] === "next") p.next()
                                            else if (modelData[1] === "shuffle") { if (p.shuffleSupported) p.shuffle = !p.shuffle }
                                            else if (modelData[1] === "loop") { if (p.loopSupported) p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist : MprisLoopState.None }
                                            else p.togglePlaying() } }
                                }
                            }
                        }
                    }

                    // ===== 02 quick =====
                    Head { num: "02"; title: "QUICK"; jp: "操作" }
                    Grid {
                        width: parent.width; columns: 3; spacing: 6
                        Repeater {
                            model: [
                                ["\u{f0594}", "night light", SysState.night, () => SysState.toggleNight()],
                                ["\u{f009b}", "silent", Notifs.dnd, () => { Notifs.dnd = !Notifs.dnd }],
                                ["\u{f0176}", "keep awake", SysState.awake, () => SysState.toggleAwake()],
                                ["\u{f04c5}", "performance", SysState.perf, () => SysState.setProfile(SysState.perf ? "balanced" : "performance")],
                                ["\u{f036c}", "clean mic", !!SysState.fx.mic, () => SysState.fxToggle("mic")],
                                ["\u{f0eb5}", "game mode", SysState.gameMode,
                                 () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode }]
                            ]
                            Rectangle {
                                required property var modelData
                                readonly property bool on: modelData[2]
                                width: (parent.width - 12) / 3; height: 58; radius: 2
                                color: on ? Theme.on : (qm.containsMouse ? "#12ffffff" : "transparent")
                                border.width: 1; border.color: on ? Theme.on : "#26ffffff"
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Text { x: 10; y: 9; text: modelData[0]; color: parent.on ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 16 }
                                Text { x: parent.width - width - 8; y: 9; text: parent.on ? "ON" : "OFF"; color: parent.on ? "#66000000" : "#4a4a4a"; font.family: Theme.font; font.pixelSize: 8; font.letterSpacing: 1.5 }
                                Text { x: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; text: modelData[1].toUpperCase(); color: parent.on ? Theme.onText : "#b0b0b0"
                                       font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.2; font.bold: parent.on }
                                MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[3]() }
                            }
                        }
                    }

                    // ===== 03 sound =====
                    Head { num: "03"; title: "SOUND"; jp: "音響"; note: SysState.fx.eq ? "eq " + SysState.fx.preset : "" }
                    CcSlider {
                        icon: "\u{f057e}"; text: cc.nice(cc.sink).slice(0, 22)
                        muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                        value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                        onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                        onIconClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                    }
                    CcSlider {
                        icon: muted ? "\u{f036d}" : "\u{f036c}"; text: "microphone"
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
                        options: [["off", "eq off"], ["music", "music"], ["vocal", "vocal"], ["games", "games"], ["bass", "bass"]]
                        current: SysState.fx.eq ? SysState.fx.preset : "off"
                        onPicked: v => { if (v === "off") { if (SysState.fx.eq) SysState.fxToggle("eq"); return }
                                         if (!SysState.fx.eq) SysState.fxToggle("eq"); SysState.fxPreset(v) }
                    }
                    AppVolumes { id: apps; visible: apps.apps.length > 0; showTitle: false }

                    // ===== 04 screens =====
                    Head { num: "04"; title: "SCREENS"; jp: "表示"; note: SysState.night ? "night light on" : "" }
                    Repeater {
                        model: [["DP-1", "main"], ["DP-2", "side"]]
                        CcSlider {
                            required property var modelData
                            icon: "\u{f00df}"; text: modelData[1]
                            value: (cc.bright[modelData[0]] || 0) / 100
                            onMoved: v => cc.setBright(modelData[0], Math.round(v * 100))
                        }
                    }

                    // ===== 05 system =====
                    Head { num: "05"; title: "SYSTEM"; jp: "系統"; note: "↓ " + cc.speed(Stats.d.netRx || 0) + "  ↑ " + cc.speed(Stats.d.netTx || 0) }
                    Bar { label: "CPU"; value: Stats.d.cpu / 100; val: Stats.d.cpu + "%"; extra: Stats.d.cpuTemp + "°  " + Stats.d.cpuFreq + "G" }
                    Bar { label: "GPU"; value: Stats.d.gpu / 100; val: Stats.d.gpu + "%"; extra: Stats.d.gpuTemp + "°  " + Stats.d.gpuPower + "W" }
                    Bar { label: "RAM"; value: Stats.d.ram / 100; val: Stats.d.ram + "%"; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + "G" }
                    Bar { label: "VRAM"; value: Stats.d.vramTotal ? Stats.d.vramUsed / Stats.d.vramTotal : 0
                          val: Math.round(Stats.d.vramTotal ? 100 * Stats.d.vramUsed / Stats.d.vramTotal : 0) + "%"; extra: (Stats.d.vramUsed || 0).toFixed(1) + " / " + (Stats.d.vramTotal || 0).toFixed(0) + "G" }

                    // ===== 06 notifications =====
                    Head { num: "06"; title: "NOTIFICATIONS"; jp: "通知"; note: Notifs.count > 0 ? String(Notifs.count) : "" }
                    Text { visible: Notifs.count === 0; width: parent.width; horizontalAlignment: Text.AlignHCenter; topPadding: 6; bottomPadding: 6
                           text: "all caught up"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11 }
                    Column {
                        visible: Notifs.count > 0; width: parent.width; spacing: 6
                        Repeater {
                            model: Notifs.model
                            NotifCard { required property var modelData; required property int index; visible: index < 6; notif: modelData; width: parent.width }
                        }
                        Rectangle {
                            width: parent.width; height: 28; radius: 2
                            color: clr.containsMouse ? "#14ffffff" : "transparent"; border.width: 1; border.color: "#26ffffff"
                            Text { anchors.centerIn: parent; text: "CLEAR ALL"; color: "#a0a0a0"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                            MouseArea { id: clr; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                        }
                    }
                    Item { width: 1; height: 4 }
                }
            }

            // ---------- footer: shortcuts, tray, updates ----------
            Item {
                id: foot
                anchors.bottom: parent.bottom; width: parent.width; height: 96
                Rectangle { x: 1; width: parent.width - 2; height: 1; color: "#26ffffff" }
                Row {
                    x: 18; y: 12; spacing: 6
                    Repeater {
                        model: [["\u{f0100}", () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                                ["\u{f0d52}", () => cc.go(["sh", "-c", "sleep 0.3; hyprpicker -a"])],
                                ["\u{f014c}", () => cc.qs("clipboard")], ["\u{f0785}", () => cc.qs("emoji")],
                                ["\u{f02e9}", () => cc.qs("wallpaper")], ["\u{f082e}", () => cc.qs("notes")],
                                ["\u{f0eb5}", () => cc.qs("games")], ["\u{f030c}", () => cc.qs("keys")], ["\u{f02dc}", () => cc.qs("home")]]
                        IconBtn { required property var modelData; width: (480 - 36 - 48) / 9; icon: modelData[0]; onHit: modelData[1]() }
                    }
                }
                RowLayout {
                    x: 18; y: 56; width: parent.width - 36; spacing: 12
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 18; height: 18
                            IconImage { id: trIcon; anchors.fill: parent; source: modelData.icon; visible: false }
                            MultiEffect { anchors.fill: trIcon; source: trIcon; saturation: -1.0; opacity: trM.containsMouse ? 1 : 0.65 }
                            MouseArea {
                                id: trM; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                        width: ul.implicitWidth + 22; height: 26; radius: 2
                        color: uM.containsMouse ? "#ffffff" : Theme.on
                        Text { id: ul; anchors.centerIn: parent; text: "UPDATE " + Updates.total; color: Theme.onText; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; font.bold: true }
                        MouseArea { id: uM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: cc.go(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                    }
                }
            }
        }
    }
}
