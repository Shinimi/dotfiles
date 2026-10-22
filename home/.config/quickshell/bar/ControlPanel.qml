// Control center (SUPER + A, or the sliders icon in the bar). One panel under the right end of the bar:
//   hero    — big thin clock, date and today's line over your blurred wallpaper (the album art while music plays)
//   toggles — a row of round switches
//   mixer   — vertical faders for volume, mic and both screens, like a little mixing desk; output + EQ below
//   system  — live line graphs for CPU, GPU and RAM
//   then notifications, shortcuts and the tray. Esc or click outside closes. Made by Claude.
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
    Timer { id: hideLater; interval: 260; onTriggered: if (!cc.visible) cc.shown = false }
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
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }

    // last 40 readings for the graphs (every 2 s while open, every 30 s otherwise — so there's history when you open it)
    property var hCpu: []; property var hGpu: []; property var hRam: []
    Connections {
        target: Stats
        function onDChanged() {
            const push = (a, v) => a.concat([v || 0]).slice(-40)
            cc.hCpu = push(cc.hCpu, Stats.d.cpu); cc.hGpu = push(cc.hGpu, Stats.d.gpu); cc.hRam = push(cc.hRam, Stats.d.ram)
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---------- building blocks ----------
    component Caption: Text { color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 2 }
    component Round: Column {   // round toggle with a tiny label
        id: rt
        property string icon; property string name; property bool on: false
        signal hit()
        spacing: 6
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 50; height: 50; radius: 25
            color: rt.on ? Theme.on : (rm.containsMouse ? "#1affffff" : "#0dffffff")
            border.width: 1; border.color: rt.on ? Theme.on : "#22ffffff"
            Behavior on color { ColorAnimation { duration: 150 } }
            Text { anchors.centerIn: parent; text: rt.icon; color: rt.on ? Theme.onText : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 18 }
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rt.hit() }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: rt.name; color: rt.on ? "#ffffff" : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 9 }
    }
    component Fader: Column {   // vertical slider: drag or scroll; click the icon to mute
        id: fd
        property string icon; property string name; property real value: 0; property bool muted: false; property bool canMute: false
        signal moved(real v)
        signal iconHit()
        readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))
        spacing: 8
        Rectangle {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            width: 60; height: 150; radius: 14
            color: fm.containsMouse ? "#14ffffff" : "#0bffffff"; border.width: 1; border.color: "#1fffffff"
            clip: true
            Rectangle {   // the level, filling up from the bottom
                anchors.bottom: parent.bottom; width: parent.width
                height: Math.max(parent.radius * 2, parent.height * fd.shown); radius: parent.radius
                color: fd.muted ? "#2affffff" : Theme.on
                Behavior on height { enabled: !fm.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; y: 10
                text: fd.muted ? "off" : Math.round(fd.value * 100)
                color: fd.shown > 0.86 ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 12; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                text: fd.icon; color: fd.shown > 0.12 ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 17
            }
            MouseArea {
                id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; preventStealing: true
                property bool onIcon: false
                function set(my) { fd.moved(Math.max(0, Math.min(1, 1 - my / track.height))) }
                onPressed: m => { onIcon = fd.canMute && m.y > track.height - 40; if (!onIcon) set(m.y) }
                onPositionChanged: m => { if (pressed && !onIcon) set(m.y) }
                onClicked: { if (onIcon) fd.iconHit() }
                onWheel: w => fd.moved(Math.max(0, Math.min(1, fd.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
            }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: fd.name; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
    }
    component Graph: Item {   // a live line graph with a soft fill
        id: gr
        property string name; property var hist: []; property string value: ""; property string sub: ""
        Layout.fillWidth: true; Layout.preferredWidth: 1; height: 74
        Canvas {
            id: cv
            anchors.fill: parent
            property var pts: gr.hist
            onPtsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const n = pts.length; if (n < 2) return
                const step = width / 39, top = 26, h = height - top - 2
                const peak = Math.min(100, Math.max(25, Math.max.apply(null, pts) * 1.4))   // auto-scale so quiet moments still show
                const X = i => width - (n - 1 - i) * step, Y = v => top + h * (1 - Math.min(peak, v) / peak)
                c.beginPath(); c.moveTo(X(0), Y(pts[0])); for (let i = 1; i < n; i++) c.lineTo(X(i), Y(pts[i]))
                c.strokeStyle = "rgba(255,255,255,0.85)"; c.lineWidth = 1.5; c.stroke()
                c.lineTo(X(n - 1), top + h); c.lineTo(X(0), top + h); c.closePath()
                const g = c.createLinearGradient(0, top, 0, top + h); g.addColorStop(0, "rgba(255,255,255,0.16)"); g.addColorStop(1, "rgba(255,255,255,0)")
                c.fillStyle = g; c.fill()
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1fffffff" }
        Text { text: gr.name; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 2 }
        Text { anchors.right: parent.right; text: gr.value; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
        Text { anchors.right: parent.right; y: 15; text: gr.sub; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 9 }
    }
    component IconBtn: Rectangle {
        property string icon; signal hit()
        width: 32; height: 32; radius: 16
        color: ib.containsMouse ? Theme.on : "#26000000"; border.width: 1; border.color: ib.containsMouse ? Theme.on : "#26ffffff"
        Behavior on color { ColorAnimation { duration: 110 } }
        Text { anchors.centerIn: parent; text: parent.icon; color: ib.containsMouse ? Theme.onText : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 14 }
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
            width: 440
            x: parent.width - width - 10; y: Theme.barHeight + 16
            height: Math.min(parent.height - y - 12, body.implicitHeight + 28)
            radius: 18; clip: true
            color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.93), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1; border.color: "#22ffffff"
            opacity: cc.visible ? 1 : 0
            transform: Translate { y: cc.visible ? 0 : -12; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false

            Flickable {
                anchors.fill: parent; anchors.margins: 14
                contentHeight: body.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: body
                    width: parent.width; spacing: 16

                    // ================= hero =================
                    ClippingRectangle {
                        id: hero
                        width: parent.width; height: cc.player ? 236 : 176; radius: 12; color: "#0b0b0b"
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Image {
                            id: heroImg; anchors.fill: parent; visible: false; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 900
                            source: cc.player && cc.art ? cc.art : (Settings.cur("wall_main") ? "file://" + Settings.cur("wall_main") : "")
                        }
                        MultiEffect { anchors.fill: parent; source: heroImg; blurEnabled: true; blur: 1.0; blurMax: 56; brightness: -0.42; saturation: -0.35 }
                        Rectangle { anchors.fill: parent; gradient: Gradient {
                            GradientStop { position: 0.0; color: "#40000000" } GradientStop { position: 1.0; color: "#b0000000" } } }

                        Row {   // you + quick buttons, top
                            x: 14; y: 14; spacing: 10
                            ClippingRectangle {
                                width: 30; height: 30; radius: 15; color: "#222"
                                Image { anchors.fill: parent; source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face"
                                        fillMode: Image.PreserveAspectCrop; sourceSize.width: 80; asynchronous: true }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: (Settings.cur("user_name") || "yu"); color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "up " + Stats.d.uptime; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                        }
                        Row {
                            anchors.right: parent.right; anchors.rightMargin: 12; y: 13; spacing: 6
                            IconBtn { icon: "\u{f0493}"; onHit: cc.qs("settings") }
                            IconBtn { icon: "\u{f033e}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"]) }
                            IconBtn { icon: "\u{f0425}"; onHit: cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "bar", "power"]) }
                        }
                        Column {   // the clock
                            x: 18; y: 54; spacing: 2
                            Text { text: Qt.formatDateTime(clock.date, Settings.cur("clock_12h") ? "h:mm" : "HH:mm"); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 58; font.weight: Font.Thin }
                            Text { text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase(); color: "#d0d0d0"; font.family: Theme.font; font.pixelSize: 12 }
                            Text { text: "— " + Journey.today(); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10; font.italic: true; topPadding: 2 }
                        }
                        Item {   // now playing strip, bottom of the hero
                            visible: !!cc.player
                            x: 14; width: parent.width - 28; height: 46; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                            ClippingRectangle {
                                id: cov; width: 46; height: 46; radius: 8; color: "#1a1a1a"
                                Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 120 }
                            }
                            Column {
                                anchors.left: cov.right; anchors.leftMargin: 12; anchors.right: ctrls.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: "#a8a8a8"; font.family: Theme.font; font.pixelSize: 10 }
                                Rectangle {
                                    visible: !!(cc.player && cc.player.length > 0)
                                    width: parent.width; height: 2; radius: 1; color: "#33ffffff"
                                    Rectangle { height: 2; radius: 1; color: "#ffffff"; width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0 }
                                }
                            }
                            Row {
                                id: ctrls; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Repeater {
                                    model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                                    Rectangle {
                                        required property var modelData
                                        readonly property bool main: modelData[1] === "toggle"
                                        width: main ? 38 : 30; height: width; radius: width / 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: main ? (pm.containsMouse ? "#ffffff" : Theme.on) : (pm.containsMouse ? "#26ffffff" : "transparent")
                                        Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 15 : 13; color: main ? Theme.onText : "#ffffff"
                                               text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0] }
                                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const p = cc.player; if (!p) return; modelData[1] === "prev" ? p.previous() : modelData[1] === "next" ? p.next() : p.togglePlaying() } }
                                    }
                                }
                            }
                        }
                    }

                    // ================= toggles =================
                    RowLayout {
                        width: parent.width; spacing: 0
                        Round { Layout.fillWidth: true; icon: "\u{f0594}"; name: "night"; on: SysState.night; onHit: SysState.toggleNight() }
                        Round { Layout.fillWidth: true; icon: "\u{f009b}"; name: "silent"; on: Notifs.dnd; onHit: Notifs.dnd = !Notifs.dnd }
                        Round { Layout.fillWidth: true; icon: "\u{f0176}"; name: "awake"; on: SysState.awake; onHit: SysState.toggleAwake() }
                        Round { Layout.fillWidth: true; icon: "\u{f04c5}"; name: "boost"; on: SysState.perf; onHit: SysState.setProfile(SysState.perf ? "balanced" : "performance") }
                        Round { Layout.fillWidth: true; icon: "\u{f036c}"; name: "clean mic"; on: !!SysState.fx.mic; onHit: SysState.fxToggle("mic") }
                        Round { Layout.fillWidth: true; icon: "\u{f0eb5}"; name: "game"; on: SysState.gameMode
                                onHit: { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode } }
                    }

                    // ================= mixer =================
                    Rectangle {
                        width: parent.width; height: mix.implicitHeight + 28; radius: 12
                        color: "#08ffffff"; border.width: 1; border.color: "#14ffffff"
                        Column {
                            id: mix
                            x: 14; y: 14; width: parent.width - 28; spacing: 14
                            RowLayout {
                                width: parent.width; spacing: 0
                                Fader {
                                    Layout.fillWidth: true; icon: "\u{f057e}"; name: "VOLUME"; canMute: true
                                    muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                                    value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                                    onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                                    onIconHit: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                                }
                                Fader {
                                    Layout.fillWidth: true; icon: muted ? "\u{f036d}" : "\u{f036c}"; name: "MIC"; canMute: true
                                    muted: !!(cc.source && cc.source.audio && cc.source.audio.muted)
                                    value: cc.source && cc.source.audio ? Math.min(1, cc.source.audio.volume) : 0
                                    onMoved: v => { if (cc.source) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                                    onIconHit: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted
                                }
                                Fader { Layout.fillWidth: true; icon: "\u{f00df}"; name: "MAIN"; value: (cc.bright["DP-1"] || 0) / 100; onMoved: v => cc.setBright("DP-1", Math.round(v * 100)) }
                                Fader { Layout.fillWidth: true; icon: "\u{f00df}"; name: "SIDE"; value: (cc.bright["DP-2"] || 0) / 100; onMoved: v => cc.setBright("DP-2", Math.round(v * 100)) }
                            }
                            Rectangle {   // output: headset / monitor
                                visible: cc.sinks.length > 1
                                width: parent.width; height: 32; radius: 16; color: "#0dffffff"
                                Row {
                                    anchors.fill: parent; anchors.margins: 3
                                    Repeater {
                                        model: cc.sinks
                                        Rectangle {
                                            required property var modelData
                                            readonly property bool cur: cc.sink && (cc.sink.id === modelData.id || (cc.sink.name === "headset_eq" && (modelData.name || "").indexOf("Fuxi") >= 0))
                                            width: parent.width / cc.sinks.length; height: parent.height; radius: height / 2
                                            color: cur ? Theme.on : (om.containsMouse ? "#14ffffff" : "transparent")
                                            Behavior on color { ColorAnimation { duration: 130 } }
                                            Text { anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                                   text: (cur ? "\u{f02cb}  " : "") + cc.nice(modelData); color: cur ? Theme.onText : "#a0a0a0"; font.family: Theme.font; font.pixelSize: 10; font.bold: cur }
                                            MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { if (cur) return; if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = modelData } }
                                        }
                                    }
                                }
                            }
                            Rectangle {   // EQ presets
                                width: parent.width; height: 30; radius: 15; color: "#0dffffff"
                                Row {
                                    anchors.fill: parent; anchors.margins: 3
                                    Repeater {
                                        model: [["off", "eq off"], ["music", "music"], ["vocal", "vocal"], ["games", "games"], ["bass", "bass"]]
                                        Rectangle {
                                            required property var modelData
                                            readonly property bool cur: modelData[0] === "off" ? !SysState.fx.eq : (!!SysState.fx.eq && SysState.fx.preset === modelData[0])
                                            width: parent.width / 5; height: parent.height; radius: height / 2
                                            color: cur ? Theme.on : (eqm.containsMouse ? "#14ffffff" : "transparent")
                                            Behavior on color { ColorAnimation { duration: 130 } }
                                            Text { anchors.centerIn: parent; text: modelData[1]; color: cur ? Theme.onText : "#a0a0a0"; font.family: Theme.font; font.pixelSize: 10; font.bold: cur }
                                            MouseArea { id: eqm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { if (modelData[0] === "off") { if (SysState.fx.eq) SysState.fxToggle("eq"); return }
                                                             if (!SysState.fx.eq) SysState.fxToggle("eq"); SysState.fxPreset(modelData[0]) } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ================= system =================
                    RowLayout {
                        width: parent.width; spacing: 16
                        Graph { name: "CPU"; hist: cc.hCpu; value: Stats.d.cpu + "%"; sub: Stats.d.cpuTemp + "°" }
                        Graph { name: "GPU"; hist: cc.hGpu; value: Stats.d.gpu + "%"; sub: Stats.d.gpuTemp + "°  " + Stats.d.gpuPower + "W" }
                        Graph { name: "RAM"; hist: cc.hRam; value: Stats.d.ram + "%"; sub: Stats.d.ramUsed.toFixed(1) + "G" }
                    }

                    // ================= notifications =================
                    Item {
                        width: parent.width; height: 14
                        Caption { text: Notifs.count > 0 ? "NOTIFICATIONS  ·  " + Notifs.count : "NO NEW NOTIFICATIONS" }
                        Text {
                            visible: Notifs.count > 0; anchors.right: parent.right
                            text: "clear"; color: clr.containsMouse ? "#ffffff" : "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10
                            MouseArea { id: clr; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                        }
                    }
                    Column {
                        visible: Notifs.count > 0; width: parent.width; spacing: 6
                        Repeater {
                            model: Notifs.model
                            NotifCard { required property var modelData; required property int index; visible: index < 3; notif: modelData; width: parent.width }
                        }
                    }

                    // ================= shortcuts + tray =================
                    Rectangle { width: parent.width; height: 1; color: "#14ffffff" }
                    RowLayout {
                        width: parent.width; spacing: 4
                        Repeater {
                            model: [["\u{f0100}", "snip", () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                                    ["\u{f0d52}", "colour", () => cc.go(["sh", "-c", "sleep 0.3; hyprpicker -a"])],
                                    ["\u{f014c}", "clips", () => cc.qs("clipboard")], ["\u{f02e9}", "walls", () => cc.qs("wallpaper")],
                                    ["\u{f082e}", "notes", () => cc.qs("notes")], ["\u{f0eb5}", "games", () => cc.qs("games")], ["\u{f030c}", "keys", () => cc.qs("keys")]]
                            Item {
                                required property var modelData
                                Layout.fillWidth: true; height: 44
                                Rectangle { anchors.fill: parent; radius: 10; color: sh.containsMouse ? "#14ffffff" : "transparent" }
                                Column {
                                    anchors.centerIn: parent; spacing: 3
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: sh.containsMouse ? "#ffffff" : "#c8c8c8"; font.family: Theme.font; font.pixelSize: 15 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 8 }
                                }
                                MouseArea { id: sh; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
                            }
                        }
                    }
                    RowLayout {
                        width: parent.width; spacing: 12
                        visible: SystemTray.items.values.length > 0 || Updates.total > 0
                        Repeater {
                            model: SystemTray.items
                            Item {
                                required property var modelData
                                width: 16; height: 16
                                IconImage { id: trIcon; anchors.fill: parent; source: modelData.icon; visible: false }
                                MultiEffect { anchors.fill: trIcon; source: trIcon; saturation: -1.0; opacity: trM.containsMouse ? 1 : 0.55 }
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
                        Text {
                            visible: Updates.total > 0
                            text: "\u{f06b0}  " + Updates.total + " updates"; color: um.containsMouse ? "#ffffff" : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10
                            MouseArea { id: um; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: cc.go(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                        }
                    }
                }
            }
        }
    }
}
