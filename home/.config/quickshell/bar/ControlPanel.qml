// Control center (SUPER + A, or the sliders icon in the bar), under the right end of the bar. "Rail with pages":
//   left rail: Home · Sound & screens · Weather · Screen time · System · Notifications, then settings / lock / power
//   always on top: greeting, the big now-playing block, 8 toggles as icon squares
//   below: the page you picked (keys 1-6 switch too). Closing goes back to Home and today. Esc or click outside closes.
//   Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
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
        if (visible) { shown = true; now = new Date(); page = 0; pickDay = ""; stWeek = false; PopupState.current = cc; SysState.refresh(); Battery.refresh(); brGet.running = true; ScreenTime.loadWeek() }
        else hideLater.restart()
    }
    Timer { id: hideLater; interval: 220; onTriggered: if (!cc.visible) { cc.shown = false; cc.page = 0; cc.pickDay = "" } }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== cc) cc.visible = false } }
    IpcHandler { target: "panel"; function toggle(): void { cc.toggle() } function page(n: int): void { cc.visible = true; cc.page = n } }
    property bool _statsOn: visible
    on_StatsOnChanged: Stats.watchers = Math.max(0, Stats.watchers + (_statsOn ? 1 : -1))

    // ---------- pages ----------
    property int page: 0
    readonly property var pages: [["\u{f02dc}", "Home"], ["\u{f057e}", "Sound & screens"], ["\u{f0599}", "Weather"],
                                  ["\u{f051f}", "Screen time"], ["\u{f04bc}", "System"], ["\u{f009a}", "Notifications"]]

    // ---------- data ----------
    property date now: new Date()
    Timer { running: cc.visible; interval: 30000; repeat: true; onTriggered: cc.now = new Date() }
    // weather page: the day you tapped in the week row ("" = today)
    property string pickDay: ""
    readonly property string todayKey: Qt.formatDate(now, "yyyy-MM-dd")
    readonly property string dayKey: pickDay || todayKey
    readonly property bool dayIsToday: dayKey === todayKey
    readonly property var dayW: Weather.week[dayKey] || null
    readonly property var todayW: Weather.week[todayKey] || null
    readonly property var dayHours: {   // 8 slots, 3 h apart: from now on for today, the whole day otherwise
        if (!dayW) return []
        if (!dayIsToday) return dayW.hours.filter(x => x.h % 3 === 0)
        const tm = new Date(now); tm.setDate(tm.getDate() + 1)
        const next = Weather.week[Qt.formatDate(tm, "yyyy-MM-dd")]
        const all = dayW.hours.filter(x => x.h >= now.getHours()).concat(next ? next.hours : [])
        return all.filter((x, i) => i % 3 === 0).slice(0, 8)
    }
    function hintFor(key) {
        const w = Weather.week[key]; if (!w) return ""
        const isToday = key === todayKey, past = key < todayKey
        const rest = isToday ? w.hours.filter(x => x.h >= now.getHours()) : w.hours
        const wet = rest.find(x => x.rain >= 50)
        let s = wet ? (past ? "Rain from " : "Rain likely from ") + String(wet.h).padStart(2, "0") + ":00" + (isToday ? ", take an umbrella" : "")
                    : (past ? "It stayed dry" : isToday ? "No rain for the rest of the day" : "No rain expected")
        if (isToday) {
            const [sh, sm] = w.sunset.split(":").map(Number), mins = sh * 60 + sm - (now.getHours() * 60 + now.getMinutes())
            if (mins > 0) s += "  ·  sunset in " + (mins >= 60 ? Math.floor(mins / 60) + "h " : "") + (mins % 60) + "m"
        }
        if (!past && w.uv >= 6) s += "  ·  UV " + w.uv + ", wear sunscreen"
        return s
    }
    // screen time page: today or the last 7 days
    property bool stWeek: false
    readonly property var stMap: stWeek ? ScreenTime.weekAll : ScreenTime.today
    readonly property var stChart: ScreenTime.days.concat([{ date: todayKey, secs: ScreenTime.total(ScreenTime.today) }])
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDev: bt ? bt.devices.values.find(d => d.connected) || null : null
    property var busy: []              // the apps using the most CPU right now: [{ name, cpu, mem }]
    Process {
        id: busyProc
        command: [cc.qsDir + "/busiest.sh"]
        stdout: StdioCollector { onStreamFinished: {
            cc.busy = this.text.trim().split("\n").map(l => l.trim().split(/\s+/)).filter(f => f.length >= 3)
                          .map(f => ({ name: f[0], cpu: parseFloat(f[1]), mem: parseInt(f[2]) / 1048576 })) } }
    }
    Timer { running: cc.visible && (cc.page === 0 || cc.page === 4); interval: 3000; repeat: true; triggeredOnStart: true; onTriggered: if (!busyProc.running) busyProc.running = true }
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
    function mem(gb) { return gb >= 1 ? gb.toFixed(1) + " GB" : Math.round(gb * 1024) + " MB" }
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
    component Card: Rectangle {   // a titled block: ICON  TITLE ··········· note   (clickable ones open a page)
        id: cd
        default property alias inner: body.data
        property string title: ""; property string icon: ""; property string note: ""
        property bool clickable: false; signal clicked()
        Layout.fillWidth: true
        implicitHeight: !title ? body.implicitHeight + 28 : body.implicitHeight > 0 ? body.implicitHeight + 52 : 42
        radius: 14; color: cdm.containsMouse ? cc.cardHi : cc.card; border.width: 1; border.color: cdm.containsMouse ? "#30ffffff" : cc.line
        Behavior on color { ColorAnimation { duration: 120 } }
        MouseArea { id: cdm; anchors.fill: parent; enabled: cd.clickable; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cd.clicked() }
        Row {
            visible: cd.title !== ""; x: 16; y: 15; spacing: 8
            Text { text: cd.icon; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 12 }
            Text { text: cd.title.toUpperCase(); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.6; font.bold: true }
        }
        Text { visible: cd.note !== ""; anchors.right: parent.right; anchors.rightMargin: 16; y: 15; text: cd.note + (cd.clickable ? "  \u{f0142}" : ""); color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
        Column { id: body; x: 16; y: cd.title ? 42 : 16; width: parent.width - 32; spacing: 10 }
    }
    component Seg: Rectangle {   // segmented choice, white pill = picked
        id: sg
        property var options: []; property var current; signal picked(var v)
        width: parent ? parent.width : 300; height: 32; radius: 9; color: "#0b0b0b"; border.width: 1; border.color: cc.line
        Row {
            anchors.fill: parent; anchors.margins: 3
            Repeater {
                model: sg.options
                Rectangle {
                    required property var modelData
                    readonly property bool on: sg.current === modelData[0]
                    width: parent.width / sg.options.length; height: parent.height; radius: 7
                    color: on ? cc.hi : (sgm.containsMouse ? "#1affffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                           text: modelData[1]; color: on ? cc.ink : "#a8a8a8"; font.family: Theme.font; font.pixelSize: 11; font.bold: on }
                    MouseArea { id: sgm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sg.picked(modelData[0]) }
                }
            }
        }
    }
    component Btn: Rectangle {   // small outlined button, white on hover
        property string text; signal hit()
        width: Math.max(38, bl.implicitWidth + 20); height: 28; radius: 8
        color: bm.containsMouse ? cc.hi : "transparent"; border.width: 1; border.color: bm.containsMouse ? cc.hi : "#2affffff"
        Behavior on color { ColorAnimation { duration: 110 } }
        Text { id: bl; anchors.centerIn: parent; text: parent.text; color: bm.containsMouse ? cc.ink : "#c8c8c8"; font.family: Theme.font; font.pixelSize: 11 }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }
    component VBar: Column {   // a tall level bar (volume, brightness): drag, scroll, or click the icon
        id: vb
        property real value: 0; property string icon: ""; property string label: ""; property bool muted: false
        signal moved(real v); signal iconClicked()
        spacing: 8
        Rectangle {
            id: track
            width: 62; height: 196; radius: 20; color: "#0b0b0b"; border.width: 1; border.color: vbm.containsMouse ? "#30ffffff" : cc.line
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 4
                height: Math.max(36, (parent.height - 8) * Math.max(0, Math.min(1, vb.value)))
                radius: 16; color: vb.muted ? "#2e2e2e" : cc.hi
                Behavior on height { NumberAnimation { duration: 90 } }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 12; text: vb.muted ? "off" : Math.round(vb.value * 100) + "%"
                   color: vb.value > 0.9 && !vb.muted ? cc.ink : "#c8c8c8"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
            MouseArea {
                id: vbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeVerCursor
                function put(y) { vb.moved(Math.max(0, Math.min(1, 1 - (y - 4) / (height - 8)))) }
                onPressed: m => put(m.y)
                onPositionChanged: m => { if (pressed) put(m.y) }
                onWheel: w => vb.moved(Math.max(0, Math.min(1, vb.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
            }
            Rectangle {   // the icon sits in the fill; click it to mute
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                width: 30; height: 30; radius: 15; color: vim.containsMouse ? "#22000000" : "transparent"
                Text { anchors.centerIn: parent; text: vb.icon; font.family: Theme.font; font.pixelSize: 15; color: vb.muted ? "#9a9a9a" : cc.ink }
                MouseArea { id: vim; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: vb.iconClicked() }
            }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: vb.label; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
    }
    component AppIcon: Item {   // an app's icon, grey like the rest
        property string name: ""
        width: 18; height: 18
        readonly property string path: Quickshell.iconPath(name, true)
        IconImage { id: aii; anchors.fill: parent; visible: false; source: parent.path }
        MultiEffect { anchors.fill: aii; source: aii; saturation: -1.0; opacity: 0.9; visible: parent.path !== "" }
        Text { anchors.centerIn: parent; visible: parent.path === ""; text: "\u{f0614}"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: parent.height - 2 }
    }
    component Page: Item {   // one page of the lower area; fades in when picked
        property int n
        anchors.fill: parent
        opacity: cc.page === n ? 1 : 0; visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        transform: Translate { x: cc.page === n ? 0 : 10; Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
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
            width: 724
            x: parent.width - width - 10; y: Theme.barHeight + 16
            height: main.implicitHeight + 36
            radius: 18
            color: "#f20c0c0c"
            border.width: 1; border.color: "#24ffffff"
            opacity: cc.visible ? 1 : 0
            transform: Translate { y: cc.visible ? 0 : -8; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 160 } }
            MouseArea { anchors.fill: parent }
            focus: cc.visible
            Keys.onEscapePressed: cc.visible = false
            Keys.onPressed: e => { if (e.key >= Qt.Key_1 && e.key <= Qt.Key_6) { cc.page = e.key - Qt.Key_1; e.accepted = true } }

            RowLayout {
                id: main
                x: 18; y: 18; width: parent.width - 36; spacing: 16

                // ================= the rail =================
                Rectangle {
                    Layout.fillHeight: true; Layout.preferredWidth: 54
                    radius: 16; color: "#0a0a0a"; border.width: 1; border.color: cc.line
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 7; spacing: 6
                        Repeater {
                            model: cc.pages
                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool on: cc.page === index
                                width: 40; height: 40; radius: 12
                                color: on ? cc.hi : rm.containsMouse ? "#1cffffff" : "transparent"
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Text { anchors.centerIn: parent; text: modelData[0]; color: parent.on ? cc.ink : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 17 }
                                Rectangle {   // unread notifications
                                    visible: index === 5 && Notifs.count > 0 && !parent.on
                                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
                                    width: 7; height: 7; radius: 4; color: "#ffffff"
                                }
                                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cc.page = index }
                            }
                        }
                    }
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 7; spacing: 6
                        Rectangle { width: 24; height: 1; color: cc.line; anchors.horizontalCenter: parent.horizontalCenter }
                        Repeater {
                            model: [["\u{f0493}", () => cc.qs("settings")],
                                    ["\u{f033e}", () => cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "curtain", "lock"])],
                                    ["\u{f0425}", () => cc.go(["qs", "ipc", "-p", cc.qsDir, "call", "bar", "power"])]]
                            Rectangle {
                                required property var modelData
                                width: 40; height: 40; radius: 12
                                color: sm.containsMouse ? cc.hi : "transparent"
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Text { anchors.centerIn: parent; text: modelData[0]; color: sm.containsMouse ? cc.ink : "#9a9a9a"; font.family: Theme.font; font.pixelSize: 16 }
                                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                            }
                        }
                    }
                }

                // ================= everything else =================
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 12

                    // ---- greeting ----
                    RowLayout {
                        Layout.fillWidth: true; spacing: 14
                        ClippingRectangle {
                            width: 44; height: 44; radius: 22; color: cc.card
                            Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 96; asynchronous: true
                                    source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face" }
                        }
                        Column {
                            Layout.fillWidth: true; spacing: 4
                            Text { text: cc.greeting + ", " + (n => n.charAt(0).toUpperCase() + n.slice(1).toLowerCase())(Settings.cur("user_name") || "yu"); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 17; font.bold: true }
                            Text {
                                text: Qt.formatDate(cc.now, "dddd d MMMM") + "   ·   up " + Stats.d.uptime
                                      + (Battery.known ? "   ·   " + Battery.icon + " " + Battery.percent + "%" + (Battery.charging ? " charging" : "") : "")
                                color: cc.dim; font.family: Theme.font; font.pixelSize: 11
                            }
                        }
                        Text { text: Qt.formatTime(cc.now, "HH:mm"); color: "#3a3a3a"; font.family: Theme.font; font.pixelSize: 30; font.bold: true }
                    }

                    // ---- now playing: big cover, controls under the title ----
                    ClippingRectangle {
                        visible: !!(cc.player && cc.player.trackTitle)
                        Layout.fillWidth: true; height: 148; radius: 16; color: cc.card
                        border.width: 1; border.color: cc.line
                        Image { id: artBg; anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false; sourceSize.width: 300 }
                        MultiEffect {   // the cover, blurred and greyed, as a backdrop
                            anchors.fill: parent; source: artBg; visible: cc.art !== ""
                            blurEnabled: true; blur: 1.0; blurMax: 64; saturation: -1.0; brightness: -0.3; opacity: 0.65
                        }
                        Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#b0080808" } GradientStop { position: 1; color: "#60080808" } } }
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 18
                            ClippingRectangle {
                                width: 120; height: 120; radius: 12; color: cc.cardHi
                                Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 240 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor   // the cover opens the player
                                            onClicked: { if (cc.player && cc.player.canRaise) { cc.visible = false; cc.player.raise() } } }
                            }
                            Column {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 4
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? cc.player.trackTitle : ""; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
                                Text { width: parent.width; elide: Text.ElideRight; text: cc.player ? (cc.player.trackArtist || cc.player.identity) : ""; color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 12 }
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
                                Item { width: 1; height: 4 }
                                Row {   // shuffle · prev · play · next · repeat
                                    spacing: 8
                                    Repeater {
                                        model: ["shuffle", "prev", "toggle", "next", "loop"]
                                        Rectangle {
                                            required property string modelData
                                            readonly property bool main: modelData === "toggle"
                                            readonly property bool extra: modelData === "shuffle" || modelData === "loop"
                                            readonly property bool supported: !extra || !!(cc.player && (modelData === "shuffle" ? cc.player.shuffleSupported : cc.player.loopSupported))
                                            readonly property bool on: !!cc.player && (modelData === "shuffle" ? cc.player.shuffle : modelData === "loop" ? cc.player.loopState !== MprisLoopState.None : true)
                                            visible: supported
                                            width: main ? 44 : 34; height: width; radius: width / 2; anchors.verticalCenter: parent.verticalCenter
                                            color: main ? (pm.containsMouse ? "#ffffff" : cc.hi) : (pm.containsMouse ? "#26ffffff" : "transparent")
                                            Text { anchors.centerIn: parent; font.family: Theme.font; font.pixelSize: main ? 19 : extra ? 14 : 16
                                                   color: main ? cc.ink : extra && !parent.on ? "#5e5e5e" : "#e6e6e6"
                                                   text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}")
                                                       : modelData === "prev" ? "\u{f04ae}" : modelData === "next" ? "\u{f04ad}" : modelData === "shuffle" ? "\u{f049d}"
                                                       : cc.player && cc.player.loopState === MprisLoopState.Track ? "\u{f0458}" : "\u{f0456}" }
                                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const p = cc.player; if (!p) return
                                                    if (modelData === "prev") p.previous(); else if (modelData === "next") p.next(); else if (modelData === "toggle") p.togglePlaying()
                                                    else if (modelData === "shuffle") p.shuffle = !p.shuffle
                                                    else p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                                                } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- toggles: icon squares, solid white when on ----
                    GridLayout {
                        Layout.fillWidth: true; columns: 8; columnSpacing: 8
                        Repeater {
                            model: [
                                ["\u{f0594}", "Night", SysState.night ? "Warm" : "", SysState.night, () => SysState.toggleNight()],
                                ["\u{f009b}", "Silent", Notifs.dnd ? (Notifs.dndUntil > 0 ? Qt.formatTime(new Date(Notifs.dndUntil), "HH:mm") : "On") : "", Notifs.dnd, () => { Notifs.dnd = !Notifs.dnd }],
                                ["\u{f0176}", "Awake", "", SysState.awake, () => SysState.toggleAwake()],
                                ["\u{f04c5}", "Power", SysState.perf ? "Max" : "", SysState.perf, () => SysState.setProfile(SysState.perf ? "balanced" : "performance")],
                                ["\u{f0197}", "Mono", Settings.cur("mono_mode") && SysState.gameMode ? "Paused" : "", !!Settings.cur("mono_mode"), () => Settings.setNow("mono_mode", !Settings.cur("mono_mode"))],
                                ["\u{f036c}", "Clean mic", "", !!SysState.fx.mic, () => SysState.fxToggle("mic")],
                                ["\u{f0eb5}", "Game", SysState.gameMode ? "" : "Auto", SysState.gameMode,
                                 () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode }],
                                ["\u{f00af}", "Bluetooth", cc.bt && cc.bt.enabled && cc.btDev ? cc.btDev.name : "", !!(cc.bt && cc.bt.enabled), () => { if (cc.bt) cc.bt.enabled = !cc.bt.enabled }]
                            ]
                            Rectangle {
                                id: tile
                                required property var modelData
                                readonly property bool on: modelData[3]
                                Layout.fillWidth: true; Layout.preferredWidth: 1; height: 74; radius: 16
                                color: on ? (tm.containsMouse ? "#ffffff" : cc.hi) : (tm.containsMouse ? cc.cardHi : cc.card)
                                border.width: 1; border.color: on ? "transparent" : tm.containsMouse ? "#30ffffff" : cc.line
                                Behavior on color { ColorAnimation { duration: 150 } }
                                scale: tm.pressed ? 0.95 : 1
                                Behavior on scale { NumberAnimation { duration: 90 } }
                                Column {
                                    anchors.centerIn: parent; width: parent.width - 8; spacing: 4
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData[0]; color: tile.on ? cc.ink : "#e6e6e6"; font.family: Theme.font; font.pixelSize: 19 }
                                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tile.modelData[1]
                                           color: tile.on ? cc.ink : "#b8b8b8"; font.family: Theme.font; font.pixelSize: 10; font.bold: tile.on }
                                    Text { visible: tile.modelData[2] !== ""; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tile.modelData[2]
                                           color: tile.on ? "#80000000" : "#666666"; font.family: Theme.font; font.pixelSize: 9 }
                                }
                                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.modelData[4]() }
                            }
                        }
                    }

                    // ================= the page area =================
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: 404

                        // ---------- 0 · Home: a glance at everything ----------
                        Page {
                            n: 0
                            ColumnLayout {
                                anchors.fill: parent; spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 10
                                    Card {   // weather, now
                                        Layout.preferredWidth: 1; Layout.preferredHeight: 156; Layout.alignment: Qt.AlignTop
                                        title: "Weather"; icon: "\u{f0599}"; note: Weather.ready ? Weather.place : ""
                                        clickable: true; onClicked: cc.page = 2
                                        Row {
                                            spacing: 12
                                            Text { text: Weather.icon; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 34; anchors.verticalCenter: parent.verticalCenter }
                                            Column {
                                                spacing: 2
                                                Text { text: Weather.ready ? Weather.temp + "°" : "–"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 26; font.bold: true }
                                                Text { text: Weather.desc + (cc.todayW ? "  ·  " + cc.todayW.max + "° " + cc.todayW.min + "°" : ""); color: cc.dim; font.family: Theme.font; font.pixelSize: 10 }
                                            }
                                        }
                                        Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: cc.hintFor(cc.todayKey)
                                               color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10 }
                                    }
                                    Card {   // screen time, today
                                        Layout.preferredWidth: 1; Layout.preferredHeight: 156; Layout.alignment: Qt.AlignTop
                                        title: "Screen time"; icon: "\u{f051f}"; note: "today"
                                        clickable: true; onClicked: cc.page = 3
                                        Text { text: ScreenTime.fmt(ScreenTime.total(ScreenTime.today)); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 22; font.bold: true }
                                        Repeater {
                                            model: ScreenTime.top(ScreenTime.today, 3)
                                            RowLayout {
                                                id: hst
                                                required property var modelData
                                                width: parent.width; spacing: 8
                                                AppIcon { name: ScreenTime.iconOf(hst.modelData.key); width: 14; height: 14 }
                                                Text { Layout.preferredWidth: 90; elide: Text.ElideRight; text: hst.modelData.label; color: "#d0d0d0"; font.family: Theme.font; font.pixelSize: 10 }
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 4; radius: 2; color: "#1fffffff"
                                                    Rectangle { height: 4; radius: 2; color: cc.hi; width: Math.max(4, parent.width * hst.modelData.secs / Math.max(1, ScreenTime.top(ScreenTime.today, 1)[0].secs)) }
                                                }
                                                Text { text: ScreenTime.fmt(hst.modelData.secs); color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 9 }
                                            }
                                        }
                                    }
                                }
                                Card {   // system strip
                                    title: "System"; icon: "\u{f04bc}"; note: cc.busy.length ? "busiest: " + cc.busy[0].name : ""
                                    clickable: true; onClicked: cc.page = 4
                                    Row {
                                        width: parent.width; spacing: 0
                                        Repeater {
                                            model: [["CPU", Stats.d.cpu + "%", Stats.d.cpuTemp + "°"], ["GPU", Stats.d.gpu + "%", Stats.d.gpuTemp + "°"],
                                                    ["RAM", Stats.d.ram + "%", Stats.d.ramUsed.toFixed(1) + " GB"], ["NET", "\u{f0045} " + cc.speed(Stats.d.netRx || 0), "\u{f005d} " + cc.speed(Stats.d.netTx || 0)]]
                                            Row {
                                                required property var modelData
                                                width: parent.width / 4; spacing: 8
                                                Text { text: modelData[0]; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.2; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                                Column {
                                                    Text { text: modelData[1]; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: modelData[0] === "NET" ? 10 : 15; font.bold: true }
                                                    Text { text: modelData[2]; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 9 }
                                                }
                                            }
                                        }
                                    }
                                }
                                Card {   // timer
                                    RowLayout {
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
                                Item { Layout.fillHeight: true }
                                GridLayout {   // shortcuts
                                    Layout.fillWidth: true; columns: 8; columnSpacing: 8
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
                                            Layout.fillWidth: true; Layout.preferredWidth: 1; height: 58; radius: 14
                                            color: qm.containsMouse ? cc.hi : cc.card; border.width: 1; border.color: qm.containsMouse ? cc.hi : cc.line
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Column {
                                                anchors.centerIn: parent; spacing: 5
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: qm.containsMouse ? cc.ink : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 17 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: qm.containsMouse ? cc.ink : cc.dim; font.family: Theme.font; font.pixelSize: 9 }
                                            }
                                            MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
                                        }
                                    }
                                }
                            }
                        }

                        // ---------- 1 · Sound & screens: tall bars left, the rest right ----------
                        Page {
                            n: 1
                            RowLayout {
                                anchors.fill: parent; spacing: 12
                                Rectangle {
                                    Layout.fillHeight: true; Layout.preferredWidth: bars.implicitWidth + 32
                                    radius: 14; color: cc.card; border.width: 1; border.color: cc.line
                                    Row {
                                        id: bars
                                        anchors.centerIn: parent; spacing: 12
                                        VBar {
                                            label: "Volume"; icon: muted ? "\u{f075f}" : "\u{f057e}"
                                            muted: !!(cc.sink && cc.sink.audio && cc.sink.audio.muted)
                                            value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                                            onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                                            onIconClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted
                                        }
                                        VBar {
                                            label: "Mic"; icon: muted ? "\u{f036d}" : "\u{f036c}"
                                            muted: !!(cc.source && cc.source.audio && cc.source.audio.muted)
                                            value: cc.source && cc.source.audio ? Math.min(1, cc.source.audio.volume) : 0
                                            onMoved: v => { if (cc.source) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                                            onIconClicked: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted
                                        }
                                        Rectangle { width: 1; height: 196; color: cc.line }
                                        Repeater {
                                            model: [["DP-1", "Main"], ["DP-2", "Side"]]
                                            VBar {
                                                required property var modelData
                                                label: modelData[1]; icon: "\u{f00df}"
                                                value: (cc.bright[modelData[0]] || 0) / 100
                                                onMoved: v => cc.setBright(modelData[0], Math.round(v * 100))
                                            }
                                        }
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
                                    Card {
                                        title: "Output"; icon: "\u{f02cb}"; note: cc.nice(cc.sink).slice(0, 26)
                                        Seg {
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
                                    }
                                    Card {   // every app that's making sound, with its own volume
                                        Layout.fillHeight: true
                                        title: "Apps"; icon: "\u{f0388}"; note: Streams.apps.length ? Streams.apps.length + " playing" : "nothing playing"
                                        Repeater {
                                            model: Streams.apps
                                            RowLayout {
                                                id: av
                                                required property var modelData
                                                readonly property bool muted: Streams.appMuted(modelData)
                                                width: parent.width; height: 26; spacing: 10
                                                Item {
                                                    width: 18; height: 18
                                                    AppIcon { anchors.fill: parent; name: av.modelData.icon || "audio-x-generic"; opacity: av.muted ? 0.35 : 1 }
                                                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Streams.toggleAppMute(av.modelData) }
                                                }
                                                Text { Layout.preferredWidth: 74; elide: Text.ElideRight; text: av.modelData.name; color: av.muted ? "#5a5a5a" : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 11 }
                                                Slider { Layout.fillWidth: true; value: av.muted ? 0 : Math.min(1, Streams.appVolume(av.modelData)); onMoved: v => Streams.setAppVolume(av.modelData, v) }
                                                Text { Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight; text: av.muted ? "off" : Math.round(Streams.appVolume(av.modelData) * 100) + "%"
                                                       color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---------- 2 · Weather: the week, tap a day ----------
                        Page {
                            n: 2
                            Card {
                                anchors.fill: parent
                                title: cc.dayIsToday ? "Today" : Qt.formatDate(new Date(cc.dayKey + "T12:00"), "dddd d"); icon: "\u{f0599}"
                                note: Weather.ready ? Weather.place : ""
                                Row {   // this week: tap a day for its weather, tap it again (or close) for today
                                    width: parent.width; spacing: 6
                                    Repeater {
                                        model: 7
                                        Rectangle {
                                            id: dayBox
                                            required property int index
                                            readonly property date day: { const d = new Date(cc.now); d.setDate(d.getDate() - ((d.getDay() + 6) % 7) + index); return d }
                                            readonly property string key: Qt.formatDate(day, "yyyy-MM-dd")
                                            readonly property bool today: key === cc.todayKey
                                            readonly property bool picked: key === cc.dayKey
                                            readonly property var w: Weather.week[key] || null
                                            width: (parent.width - 36) / 7; height: 72; radius: 12
                                            color: picked ? cc.hi : dm.containsMouse ? "#14ffffff" : "transparent"
                                            border.width: 1; border.color: picked ? cc.hi : today ? "#9a9a9a" : cc.line
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(dayBox.day, "ddd"); color: dayBox.picked ? "#90000000" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dayBox.day.getDate(); color: dayBox.picked ? cc.ink : "#e0e0e0"; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; visible: !!dayBox.w
                                                       text: dayBox.w ? Weather.wmoIcon(dayBox.w.code, false) + " " + dayBox.w.max + "°" : ""
                                                       color: dayBox.picked ? "#b0000000" : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 9 }
                                            }
                                            Rectangle {   // small dot marks today when another day is picked
                                                visible: dayBox.today && !dayBox.picked
                                                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                                                width: 4; height: 4; radius: 2; color: "#d0d0d0"
                                            }
                                            MouseArea {
                                                id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: cc.pickDay = (dayBox.today || dayBox.picked) ? "" : dayBox.key
                                            }
                                        }
                                    }
                                }
                                RowLayout {   // the picked day: right now for today, the forecast (or how it was) otherwise
                                    width: parent.width; spacing: 14
                                    Text { text: cc.dayIsToday && Weather.ready ? Weather.icon : cc.dayW ? Weather.wmoIcon(cc.dayW.code, false) : ""
                                           color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 40 }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: cc.dayIsToday ? Weather.temp + "°" : cc.dayW ? cc.dayW.max + "°  " + cc.dayW.min + "°" : ""
                                               color: "#ffffff"; font.family: Theme.font; font.pixelSize: 30; font.bold: true }
                                        Text { width: parent.width; elide: Text.ElideRight
                                               text: cc.dayIsToday ? Weather.desc + " · feels " + Weather.feels + "°" + (cc.dayW ? " · " + cc.dayW.max + "° " + cc.dayW.min + "°" : "")
                                                                   : cc.dayW ? Qt.formatDate(new Date(cc.dayKey + "T12:00"), "dddd") + " · " + Weather.wmoDesc(cc.dayW.code) : ""
                                               color: cc.dim; font.family: Theme.font; font.pixelSize: 11 }
                                    }
                                    Grid {   // rain, wind, sunrise, sunset
                                        visible: !!cc.dayW
                                        columns: 2; columnSpacing: 16; rowSpacing: 6
                                        Repeater {
                                            model: cc.dayW ? [["\u{f054a}", cc.dayW.rain + "%"], ["\u{f059d}", cc.dayW.wind + " km/h"],
                                                              ["\u{f059c}", cc.dayW.sunrise], ["\u{f059b}", cc.dayW.sunset]] : []
                                            Text { required property var modelData; text: modelData[0] + "  " + modelData[1]; color: "#b0b0b0"; font.family: Theme.font; font.pixelSize: 11 }
                                        }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: cc.line }
                                Row {   // hour by hour, with a thin rain-chance bar under each
                                    visible: cc.dayHours.length > 0
                                    width: parent.width
                                    Repeater {
                                        model: cc.dayHours
                                        Column {
                                            required property var modelData
                                            required property int index
                                            width: parent.width / Math.max(1, cc.dayHours.length); spacing: 4
                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                   text: cc.dayIsToday && index === 0 ? "Now" : String(modelData.h).padStart(2, "0")
                                                   color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.wmoIcon(modelData.code, modelData.h < 6 || modelData.h >= 19)
                                                   color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 16 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "°"
                                                   color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter; width: 26; height: 3; radius: 2; color: "#1affffff"
                                                Rectangle { width: parent.width * Math.min(1, modelData.rain / 100); height: 3; radius: 2; color: "#d0d0d0" }
                                            }
                                        }
                                    }
                                }
                                Text { width: parent.width; wrapMode: Text.WordWrap; text: cc.hintFor(cc.dayKey); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11 }
                            }
                        }

                        // ---------- 3 · Screen time: 7-day chart, then the apps ----------
                        Page {
                            n: 3
                            Card {
                                anchors.fill: parent
                                title: "Screen time"; icon: "\u{f051f}"
                                note: "last 7 days  " + ScreenTime.fmt(ScreenTime.total(ScreenTime.weekAll))
                                RowLayout {
                                    width: parent.width; spacing: 18
                                    Column {
                                        Layout.alignment: Qt.AlignBottom; spacing: 2
                                        Text { text: ScreenTime.fmt(ScreenTime.total(ScreenTime.today)); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 30; font.bold: true }
                                        Text { text: "today"; color: cc.dim; font.family: Theme.font; font.pixelSize: 11 }
                                        Text {
                                            readonly property var used: ScreenTime.days.filter(d => d.secs > 0)
                                            readonly property real avg: used.length ? used.reduce((a, d) => a + d.secs, 0) / used.length : 0
                                            text: avg > 0 ? "daily average " + ScreenTime.fmt(avg) : ""; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10; topPadding: 6
                                        }
                                    }
                                    Row {   // the last 7 days as bars, today in white
                                        Layout.fillWidth: true; height: 112; spacing: 10
                                        readonly property real peak: Math.max(3600, ...cc.stChart.map(d => d.secs))
                                        Repeater {
                                            model: cc.stChart
                                            Column {
                                                required property var modelData
                                                required property int index
                                                readonly property bool isToday: index === cc.stChart.length - 1
                                                width: (parent.width - 60) / 7; spacing: 4; anchors.bottom: parent.bottom
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.secs >= 3600 ? Math.round(modelData.secs / 3600) + "h" : modelData.secs > 0 ? Math.round(modelData.secs / 60) + "m" : ""
                                                       color: parent.isToday ? "#e0e0e0" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9 }
                                                Rectangle {
                                                    anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(26, parent.width); radius: 6
                                                    height: Math.max(4, 70 * modelData.secs / parent.parent.peak)
                                                    color: parent.isToday ? cc.hi : "#3a3a3a"
                                                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                                }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(modelData.date + "T12:00"), "ddd").slice(0, 2)
                                                       color: parent.isToday ? "#ffffff" : "#6a6a6a"; font.family: Theme.font; font.pixelSize: 9; font.bold: parent.isToday }
                                            }
                                        }
                                    }
                                }
                                Seg { width: 180; options: [[false, "Today"], [true, "7 days"]]; current: cc.stWeek; onPicked: v => cc.stWeek = v }
                                Repeater {
                                    model: ScreenTime.top(cc.stMap, 5)
                                    RowLayout {
                                        id: sti
                                        required property var modelData
                                        width: parent.width; spacing: 10
                                        AppIcon { name: ScreenTime.iconOf(sti.modelData.key) }
                                        Text { Layout.preferredWidth: 130; elide: Text.ElideRight; text: sti.modelData.label; color: "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 6; radius: 3; color: "#1affffff"
                                            Rectangle { height: 6; radius: 3; color: cc.hi; width: Math.max(6, parent.width * sti.modelData.secs / Math.max(1, ScreenTime.top(cc.stMap, 1)[0].secs)) }
                                        }
                                        Text { Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight; text: ScreenTime.fmt(sti.modelData.secs); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                    }
                                }
                                Text { visible: !ScreenTime.enabled; text: "Screen time is off (Settings → Comfort)"; color: cc.dim; font.family: Theme.font; font.pixelSize: 11 }
                            }
                        }

                        // ---------- 4 · System: rings, network, who's busy ----------
                        Page {
                            n: 4
                            ColumnLayout {
                                anchors.fill: parent; spacing: 10
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
                                    title: "Busiest right now"; icon: "\u{f0a69}"; note: "up " + Stats.d.uptime
                                    Repeater {
                                        model: cc.busy
                                        RowLayout {
                                            id: bz
                                            required property var modelData
                                            width: parent.width; spacing: 10
                                            AppIcon { name: bz.modelData.name.replace(/-bin$/, ""); width: 16; height: 16 }
                                            Text { Layout.preferredWidth: 150; elide: Text.ElideRight; text: bz.modelData.name; color: "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11 }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 5; radius: 3; color: "#1affffff"
                                                Rectangle { height: 5; radius: 3; color: cc.hi; width: Math.max(5, parent.width * Math.min(1, bz.modelData.cpu / Math.max(25, cc.busy[0].cpu))) }
                                            }
                                            Text { Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight; text: Math.round(bz.modelData.cpu) + "%"; color: "#e0e0e0"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
                                            Text { Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight; text: cc.mem(bz.modelData.mem); color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 10 }
                                        }
                                    }
                                    Btn { text: "Open task manager"; onHit: cc.go(["kitty", "--class", "btop", "-e", "btop"]) }
                                }
                            }
                        }

                        // ---------- 5 · Notifications ----------
                        Page {
                            n: 5
                            Card {
                                anchors.fill: parent
                                title: "Notifications"; icon: "\u{f009a}"
                                note: Notifs.count > 0 ? Notifs.count + " new" : "all caught up"
                                ListView {
                                    visible: Notifs.count > 0
                                    width: parent.width; height: Math.min(contentHeight, 290)
                                    clip: true; spacing: 6; boundsBehavior: Flickable.StopAtBounds
                                    model: Notifs.model
                                    delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                                }
                                Column {
                                    visible: Notifs.count === 0
                                    width: parent.width; topPadding: 96; bottomPadding: 96; spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f009a}"; color: "#3a3a3a"; font.family: Theme.font; font.pixelSize: 40 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "You're all caught up"; color: cc.dim; font.family: Theme.font; font.pixelSize: 12 }
                                }
                                RowLayout {   // silence for a while, it turns itself back on
                                    width: parent.width; spacing: 6
                                    Btn { visible: Notifs.count > 0; text: "Clear all"; onHit: Notifs.clearAll() }
                                    Text { Layout.fillWidth: true; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 11
                                           text: Notifs.dnd ? (Notifs.dndUntil > 0 ? "\u{f009b}  Silent until " + Qt.formatTime(new Date(Notifs.dndUntil), "HH:mm") : "\u{f009b}  Silent") : "Silence for" }
                                    Repeater {
                                        model: Notifs.dnd ? [["Turn on", () => { Notifs.dnd = false }]]
                                                          : [["30m", () => Notifs.silenceFor(30)], ["1h", () => Notifs.silenceFor(60)], ["3h", () => Notifs.silenceFor(180)], ["Until 8:00", () => Notifs.silenceUntilMorning()]]
                                        Btn { required property var modelData; text: modelData[0]; onHit: modelData[1]() }
                                    }
                                }
                            }
                        }
                    }

                    // ---- tray + updates ----
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
                            width: upl.implicitWidth + 26; height: 32; radius: 10
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
}
