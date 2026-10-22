// Control center (SUPER + A): greeting, now playing, quick toggles, sound, apps, system,
// notifications, tray/updates and shortcuts. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

BarPopup {
    id: cc
    contentWidth: 700
    padding: 18
    readonly property string qsDir: Quickshell.env("HOME") + "/.config/quickshell/bar"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !(n.name || "").startsWith("effect_") && n.name !== "headset_eq")
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].concat(cc.sinks) }
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    // album art: keep the last picture while a new track loads (an empty image source crashes Qt 6.12)
    property string art: ""
    readonly property string liveArt: cc.player ? (cc.player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt

    onVisibleChanged: if (visible) { SysState.refresh(); brGet.running = true }
    // monitor brightness (DDC/CI); setting is debounced because the monitor is slow to answer
    property var bright: ({ "DP-1": 100, "DP-2": 100 })
    property var brPending: ({})
    readonly property string brCmd: Qt.resolvedUrl("brightness.sh").toString().replace("file://", "")
    Process { id: brGet; command: [cc.brCmd, "get"]; stdout: StdioCollector { onStreamFinished: { try { cc.bright = JSON.parse(this.text) } catch (e) {} } } }
    Timer { id: brSet; interval: 250; onTriggered: { for (const k in cc.brPending) Quickshell.execDetached([cc.brCmd, "set", k, String(cc.brPending[k])]); cc.brPending = {} } }
    function setBright(mon, v) { const b = Object.assign({}, bright); b[mon] = v; bright = b; const p = Object.assign({}, brPending); p[mon] = v; brPending = p; brSet.restart() }
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }
    function go(cmd) { cc.visible = false; Quickshell.execDetached(cmd) }
    function qs(target, fn) { go(["qs", "ipc", "-p", qsDir, "call", target, fn || "toggle"]) }
    function mmss(t) { t = Math.max(0, Math.floor(t || 0)); return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0") }
    function nice(n) { return (n ? (n.nickname || n.description || n.name || "") : "").replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") }
    readonly property string greeting: {
        Stats.d.uptime  // re-evaluate as time passes
        const h = new Date().getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }
    Timer { running: cc.visible && cc.player && cc.player.isPlaying; interval: 1000; repeat: true; onTriggered: cc.player.positionChanged() }

    // ---------- header ----------
    RowLayout {
        width: parent.width; spacing: 12
        Avatar { size: 42 }
        Column {
            Layout.fillWidth: true; spacing: 3
            Label { text: cc.greeting + ", " + (Settings.cur("user_name") || "yu"); font.pixelSize: 15; font.weight: Font.Bold }
            Label {
                text: "up " + Stats.d.uptime + (Updates.total > 0 ? "   ·   " + Updates.total + " updates" : "   ·   up to date")
                color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal
            }
        }
        Repeater {
            model: [["\u{f0493}", () => cc.qs("settings")],
                    ["\u{f033e}", () => cc.go(["loginctl", "lock-session"])],
                    ["\u{f0425}", () => cc.go([Quickshell.env("HOME") + "/.config/hypr/scripts/powermenu.sh"])]]
            Rectangle {
                required property var modelData
                width: 36; height: 36; radius: 18
                color: hm.containsMouse ? Theme.on : Theme.card
                border.width: 1; border.color: Theme.stroke
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { anchors.centerIn: parent; text: modelData[0]; color: hm.containsMouse ? Theme.onText : Theme.fgDim; font.pixelSize: 15 }
                MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
            }
        }
    }

    // ---------- now playing ----------
    ClippingRectangle {
        visible: cc.player !== null && cc.player.trackTitle !== ""
        width: parent.width; height: 104; radius: 18; color: Theme.card
        border.width: 1; border.color: Theme.stroke
        Image { id: artBg; anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false }
        MultiEffect {   // album art, blurred and greyed, as a soft backdrop
            anchors.fill: parent; source: artBg; visible: cc.art !== ""
            blurEnabled: true; blur: 1.0; blurMax: 64; saturation: -1.0; brightness: -0.25; opacity: 0.55
        }
        Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#b3080808" } GradientStop { position: 1; color: "#40080808" } } }
        RowLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 14
            ClippingRectangle {
                width: 76; height: 76; radius: 12; color: Theme.bgAlt
                Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Label { anchors.centerIn: parent; visible: cc.art === ""; text: "\u{f075a}"; font.pixelSize: 26; color: Theme.muted }
            }
            Column {
                Layout.fillWidth: true; spacing: 2
                Label { width: parent.width; text: cc.player ? cc.player.trackTitle : ""; font.pixelSize: 14; font.weight: Font.Bold; elide: Text.ElideRight }
                Label { width: parent.width; text: cc.player ? cc.player.trackArtist : ""; color: Theme.fgDim; font.pixelSize: 11; font.weight: Font.Normal; elide: Text.ElideRight }
                Item { width: 1; height: 10 }
                Item {
                    visible: cc.player && cc.player.lengthSupported && cc.player.length > 0
                    width: parent.width; height: 14
                    Label { id: tpos; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: cc.player ? cc.mmss(cc.player.position) : ""; color: Theme.muted; font.pixelSize: 9; font.weight: Font.Normal }
                    Label { id: tlen; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: cc.player ? cc.mmss(cc.player.length) : ""; color: Theme.muted; font.pixelSize: 9; font.weight: Font.Normal }
                    Rectangle {
                        anchors.left: tpos.right; anchors.right: tlen.left; anchors.margins: 8; anchors.verticalCenter: parent.verticalCenter
                        height: 4; radius: 2; color: "#26ffffff"
                        Rectangle {
                            height: parent.height; radius: 2; color: Theme.on
                            width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0
                        }
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
                        width: main ? 46 : 34; height: width; radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: main ? (pm.containsMouse ? "#ffffff" : Theme.on) : (pm.containsMouse ? "#26ffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Label {
                            anchors.centerIn: parent
                            text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0]
                            color: main ? Theme.onText : Theme.fg; font.pixelSize: main ? 20 : 16
                        }
                        MouseArea {
                            id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (!cc.player) return; if (modelData[1] === "prev") cc.player.previous(); else if (modelData[1] === "next") cc.player.next(); else cc.player.togglePlaying() }
                        }
                    }
                }
            }
        }
    }

    // ---------- quick toggles (solid white when on) ----------
    GridLayout {
        width: parent.width; columns: 3; rowSpacing: 8; columnSpacing: 8
        Repeater {
            model: [
                ["\u{f0594}", "Night light", SysState.night ? "On" : "Off", SysState.night, () => SysState.toggleNight()],
                ["\u{f009b}", "Silent", Notifs.dnd ? "No pop-ups" : "Off", Notifs.dnd, () => { Notifs.dnd = !Notifs.dnd }],
                ["\u{f0176}", "Keep awake", SysState.awake ? "No auto-lock" : "Off", SysState.awake, () => SysState.toggleAwake()],
                ["\u{f04c5}", "Performance", SysState.perf ? "Max power" : "Balanced", SysState.perf, () => SysState.setProfile(SysState.perf ? "balanced" : "performance")],
                ["\u{f036c}", "Clean mic", SysState.fx.mic ? "Noise removal on" : "Off", !!SysState.fx.mic, () => SysState.fxToggle("mic")],
                ["\u{f0eb5}", "Game mode", SysState.gameMode ? "On" : "Auto", SysState.gameMode,
                 () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode }]
            ]
            Rectangle {
                id: tile
                required property var modelData
                readonly property bool on: modelData[3]
                Layout.fillWidth: true; Layout.preferredWidth: 1
                height: 56; radius: 28
                color: on ? (tm.containsMouse ? "#ffffff" : Theme.on) : (tm.containsMouse ? Theme.cardHi : Theme.card)
                border.width: 1; border.color: on ? "transparent" : Theme.stroke
                Behavior on color { ColorAnimation { duration: 150 } }
                Rectangle {
                    id: tic
                    x: 8; anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 20
                    color: tile.on ? "#1a000000" : "#0fffffff"
                    Label { anchors.centerIn: parent; text: modelData[0]; color: tile.on ? Theme.onText : Theme.fg; font.pixelSize: 16 }
                }
                Column {
                    anchors.left: tic.right; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter; spacing: 1
                    Label { width: parent.width; text: modelData[1]; color: tile.on ? Theme.onText : Theme.fg; font.pixelSize: 12; elide: Text.ElideRight }
                    Label { width: parent.width; text: modelData[2]; color: tile.on ? "#99000000" : Theme.muted; font.pixelSize: 10; font.weight: Font.Normal; elide: Text.ElideRight }
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[4]() }
            }
        }
    }

    RowLayout {
        width: parent.width; spacing: 10

        // ================= left column =================
        Column {
            Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 10

            CcCard {
                title: "Sound"; icon: "\u{f057e}"
                CcSlider {
                    icon: "\u{f057e}"; text: cc.nice(cc.sink).slice(0, 18)
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
                // output devices: a segmented switch
                Rectangle {
                    visible: cc.sinks.length > 1
                    width: parent.width; height: 32; radius: 16; color: "#0affffff"; border.width: 1; border.color: Theme.stroke
                    Row {
                        anchors.fill: parent; anchors.margins: 3
                        Repeater {
                            model: cc.sinks
                            Rectangle {
                                required property var modelData
                                readonly property bool cur: cc.sink && (cc.sink.id === modelData.id || (cc.sink.name === "headset_eq" && (modelData.name || "").indexOf("Fuxi") >= 0))
                                width: parent.width / cc.sinks.length; height: parent.height; radius: height / 2
                                color: cur ? Theme.on : (dm.containsMouse ? "#14ffffff" : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Label { anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        text: cc.nice(modelData); color: cur ? Theme.onText : Theme.fgDim; font.pixelSize: 10 }
                                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (cur) return; if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = modelData } }
                            }
                        }
                    }
                }
                // EQ presets
                RowLayout {
                    width: parent.width; spacing: 8
                    Label { text: "EQ"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.2 }
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: 14; color: "#0affffff"; border.width: 1; border.color: Theme.stroke
                        Row {
                            anchors.fill: parent; anchors.margins: 3
                            Repeater {
                                model: [["off", "Off"], ["music", "Music"], ["vocal", "Vocal"], ["games", "Games"], ["bass", "Bass"]]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool cur: modelData[0] === "off" ? !SysState.fx.eq : (!!SysState.fx.eq && SysState.fx.preset === modelData[0])
                                    width: parent.width / 5; height: parent.height; radius: height / 2
                                    color: cur ? Theme.on : (em.containsMouse ? "#14ffffff" : "transparent")
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Label { anchors.centerIn: parent; text: modelData[1]; color: cur ? Theme.onText : Theme.fgDim; font.pixelSize: 10 }
                                    MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData[0] === "off") { if (SysState.fx.eq) SysState.fxToggle("eq"); return }
                                            if (!SysState.fx.eq) SysState.fxToggle("eq")
                                            SysState.fxPreset(modelData[0])
                                        } }
                                }
                            }
                        }
                    }
                }
                Rectangle { visible: apps.apps.length > 0; width: parent.width; height: 1; color: Theme.stroke }
                AppVolumes { id: apps; visible: apps.apps.length > 0; showTitle: false }
            }

            CcCard {
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

        // ================= right column =================
        Column {
            Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 10

            CcCard {
                title: "System"; icon: "\u{f04bc}"
                note: "\u{f0045} " + cc.speed(Stats.d.netRx || 0) + "   \u{f005d} " + cc.speed(Stats.d.netTx || 0)
                RowLayout {
                    width: parent.width; spacing: 4
                    MiniStat { title: "CPU"; usage: Stats.d.cpu; temp: Stats.d.cpuTemp; extra: Stats.d.cpuFreq + " GHz" }
                    MiniStat { title: "GPU"; usage: Stats.d.gpu; temp: Stats.d.gpuTemp; extra: Stats.d.gpuPower + " W" }
                    MiniStat { title: "RAM"; usage: Stats.d.ram; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB" }
                }
            }

            CcCard {
                title: "Today"; icon: "\u{f0599}"
                note: Weather.ready ? Weather.place : ""
                // weather now + next days
                RowLayout {
                    visible: Weather.ready
                    width: parent.width; spacing: 12
                    Label { text: Weather.icon; font.pixelSize: 30; color: Theme.fg }
                    Column {
                        spacing: 0
                        Label { text: Weather.temp + "°"; font.pixelSize: 22; font.weight: Font.Bold }
                        Label { text: Weather.desc + " · feels " + Weather.feels + "°"; color: Theme.muted; font.pixelSize: 9; font.weight: Font.Normal }
                    }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: Weather.days.slice(1, 3)
                        Column {
                            required property var modelData
                            spacing: 2
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(modelData.date), "ddd"); color: Theme.muted; font.pixelSize: 9 }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; font.pixelSize: 15 }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.max + "° " + modelData.min + "°"; color: Theme.fgDim; font.pixelSize: 9; font.weight: Font.Normal }
                        }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: Theme.stroke }
                // quick timer: pick a length, or watch it count down
                RowLayout {
                    width: parent.width; spacing: 6
                    Label {
                        text: Timers.timerActive ? "\u{f051f}  " + Timers.fmt(Timers.remaining) : "\u{f051f}  Timer"
                        color: Timers.timerRunning ? "#ffffff" : Theme.fgDim; font.pixelSize: Timers.timerActive ? 14 : 11
                        font.weight: Timers.timerActive ? Font.Bold : Font.DemiBold; Layout.fillWidth: true
                    }
                    Repeater {
                        model: Timers.timerActive ? [[Timers.timerRunning ? "\u{f03e4}" : "\u{f040a}", () => Timers.toggleTimer()], ["\u{f0450}", () => Timers.resetTimer()]]
                                                  : [["5m", () => { Timers.setMinutes(5); Timers.toggleTimer() }], ["15m", () => { Timers.setMinutes(15); Timers.toggleTimer() }],
                                                     ["25m", () => { Timers.setMinutes(25); Timers.toggleTimer() }], ["1h", () => { Timers.setMinutes(60); Timers.toggleTimer() }]]
                        Rectangle {
                            required property var modelData
                            width: Math.max(36, tl.implicitWidth + 18); height: 26; radius: 13
                            color: tmm.containsMouse ? Theme.on : "#0affffff"; border.width: 1; border.color: Theme.stroke
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Label { id: tl; anchors.centerIn: parent; text: modelData[0]; font.pixelSize: 10; color: tmm.containsMouse ? Theme.onText : Theme.fgDim }
                            MouseArea { id: tmm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                        }
                    }
                }
            }

            CcCard {
                title: "Notifications"; icon: "\u{f009a}"
                note: Notifs.count > 0 ? String(Notifs.count) : ""
                Column {
                    visible: Notifs.count === 0
                    width: parent.width; spacing: 6; topPadding: 6; bottomPadding: 10
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f009c}"; color: "#3a3a3a"; font.pixelSize: 28 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Normal }
                }
                ListView {
                    visible: Notifs.count > 0
                    width: parent.width
                    height: Math.min(contentHeight, 240)
                    clip: true; spacing: 6
                    verticalLayoutDirection: ListView.BottomToTop
                    model: Notifs.model
                    delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                }
                Rectangle {
                    visible: Notifs.count > 0
                    width: parent.width; height: 28; radius: 14
                    color: clrMouse.containsMouse ? Theme.cardHi : "#0affffff"; border.width: 1; border.color: Theme.stroke
                    Label { anchors.centerIn: parent; text: "Clear all"; color: Theme.fgDim; font.pixelSize: 10 }
                    MouseArea { id: clrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                }
            }

            CcCard {
                visible: SystemTray.items.values.length > 0 || Updates.total > 0
                RowLayout {
                    width: parent.width; spacing: 14
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 18; height: 18
                            IconImage { id: trIcon; anchors.fill: parent; source: modelData.icon; visible: false }
                            MultiEffect { anchors.fill: trIcon; source: trIcon; saturation: -1.0; opacity: trMouse.containsMouse ? 1 : 0.7 }
                            MouseArea {
                                id: trMouse; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                        width: ul.implicitWidth + 24; height: 28; radius: 14
                        color: uMouse.containsMouse ? "#ffffff" : Theme.on
                        Label { id: ul; anchors.centerIn: parent; text: "\u{f06b0}  Update " + Updates.total; color: Theme.onText; font.pixelSize: 10 }
                        MouseArea { id: uMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: cc.go(["kitty", "--class", "updater", "-e", "bash", "-c", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"]) }
                    }
                }
            }
        }
    }

    // ---------- shortcuts ----------
    RowLayout {
        width: parent.width; spacing: 8
        Repeater {
            model: [
                ["\u{f0100}", "Snip",      () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                ["\u{f0d52}", "Color",     () => cc.go(["sh", "-c", "sleep 0.3; hyprpicker -a"])],
                ["\u{f014c}", "Clipboard", () => cc.qs("clipboard")],
                ["\u{f0785}", "Emoji",     () => cc.qs("emoji")],
                ["\u{f02e9}", "Wallpaper", () => cc.qs("wallpaper")],
                ["\u{f0eb5}", "Games",     () => cc.qs("games")],
                ["\u{f0349}", "Apps",      () => cc.qs("launcher")]
            ]
            Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredWidth: 1; height: 54; radius: 16
                color: qm.containsMouse ? Theme.cardHi : Theme.card
                border.width: 1; border.color: qm.containsMouse ? "#2affffff" : Theme.stroke
                Behavior on color { ColorAnimation { duration: 120 } }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: qm.containsMouse ? "#ffffff" : Theme.fgDim; font.pixelSize: 17 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: Theme.muted; font.pixelSize: 9; font.weight: Font.Normal }
                }
                MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
            }
        }
    }
}
