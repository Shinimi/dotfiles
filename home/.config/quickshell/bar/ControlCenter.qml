// Control center (SUPER + A): greeting, now playing, quick toggles, sound, apps, system,
// notifications, tray/updates and shortcuts. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

BarPopup {
    id: cc
    contentWidth: 720
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
        Avatar { size: 46 }
        Column {
            Layout.fillWidth: true; spacing: 2
            Label { text: cc.greeting; font.pixelSize: 16; font.weight: Font.Bold }
            Label {
                text: "\u{f0954}  up " + Stats.d.uptime + (Updates.total > 0 ? "   ·   \u{f06b0}  " + Updates.total + " updates" : "   ·   up to date")
                color: Theme.muted; font.pixelSize: 11; font.weight: Font.Normal
            }
        }
        Repeater {
            model: [["\u{f0493}", "Settings", Theme.blue, () => cc.qs("settings")],
                    ["\u{f033e}", "Lock", Theme.cyan, () => cc.go(["loginctl", "lock-session"])],
                    ["\u{f0425}", "Power", Theme.red, () => cc.go([Quickshell.env("HOME") + "/.config/hypr/scripts/powermenu.sh"])]]
            Rectangle {
                required property var modelData
                width: 38; height: 38; radius: 12
                color: hm.containsMouse ? Qt.rgba(modelData[2].r, modelData[2].g, modelData[2].b, 0.2) : Theme.card
                border.width: 1; border.color: "#14efeaf8"
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { anchors.centerIn: parent; text: modelData[0]; color: hm.containsMouse ? modelData[2] : Theme.fgDim; font.pixelSize: 16 }
                MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[3]() }
            }
        }
    }

    // ---------- now playing ----------
    ClippingRectangle {
        visible: cc.player !== null && cc.player.trackTitle !== ""
        width: parent.width; height: 96; radius: 16; color: Theme.card
        border.width: 1; border.color: "#14efeaf8"
        Image {   // album art as a soft backdrop
            anchors.fill: parent; source: cc.art
            fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: 0.22
        }
        Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#cc0d0c13" } GradientStop { position: 1; color: "#330d0c13" } } }
        RowLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 14
            ClippingRectangle {
                width: 72; height: 72; radius: 12; color: Theme.bgAlt
                Image { anchors.fill: parent; source: cc.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Label { anchors.centerIn: parent; visible: cc.art === ""; text: "\u{f075a}"; font.pixelSize: 26; color: Theme.muted }
            }
            Column {
                Layout.fillWidth: true; spacing: 3
                Label { width: parent.width; text: cc.player ? cc.player.trackTitle : ""; font.pixelSize: 14; font.weight: Font.Bold; elide: Text.ElideRight }
                Label { width: parent.width; text: cc.player ? cc.player.trackArtist : ""; color: Theme.purple; font.pixelSize: 12; elide: Text.ElideRight }
                Item { width: 1; height: 6 }
                Rectangle {   // progress
                    visible: cc.player && cc.player.lengthSupported && cc.player.length > 0
                    width: parent.width; height: 4; radius: 2; color: "#33efeaf8"
                    Rectangle {
                        height: parent.height; radius: 2; color: Theme.purple
                        width: cc.player && cc.player.length > 0 ? parent.width * Math.min(1, cc.player.position / cc.player.length) : 0
                    }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: m => { if (cc.player && cc.player.canSeek) cc.player.position = (m.x / width) * cc.player.length } }
                }
            }
            Row {
                spacing: 8
                Repeater {
                    model: [["\u{f04ae}", "prev"], ["", "toggle"], ["\u{f04ad}", "next"]]
                    Rectangle {
                        required property var modelData
                        readonly property bool main: modelData[1] === "toggle"
                        width: main ? 44 : 34; height: width; radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: main ? Theme.purple : (pm.containsMouse ? "#33efeaf8" : "#22efeaf8")
                        Label {
                            anchors.centerIn: parent
                            text: main ? (cc.player && cc.player.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData[0]
                            color: main ? Theme.bg : Theme.fg; font.pixelSize: main ? 20 : 15
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

    // ---------- quick toggles ----------
    RowLayout {
        width: parent.width; spacing: 10
        Repeater {
            model: [
                ["\u{f0594}", "Night light", SysState.night ? "On" : "Off", SysState.night, Theme.yellow, () => SysState.toggleNight()],
                ["\u{f009b}", "Silent", Notifs.dnd ? "No pop-ups" : "Off", Notifs.dnd, Theme.purple, () => { Notifs.dnd = !Notifs.dnd }],
                ["\u{f0176}", "Keep awake", SysState.awake ? "No auto-lock" : "Off", SysState.awake, Theme.cyan, () => SysState.toggleAwake()],
                ["\u{f04c5}", "Performance", SysState.perf ? "Max power" : "Balanced", SysState.perf, Theme.red, () => SysState.setProfile(SysState.perf ? "balanced" : "performance")],
                ["\u{f036c}", "Clean mic", SysState.fx.mic ? "On" : "Off", !!SysState.fx.mic, Theme.cyan, () => SysState.fxToggle("mic")],
                ["\u{f0eb5}", "Game mode", SysState.gameMode ? "On" : "Auto", SysState.gameMode, Theme.red,
                 () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", SysState.gameMode ? "off" : "on"]); SysState.gameMode = !SysState.gameMode }]
            ]
            Rectangle {
                id: tile
                required property var modelData
                readonly property bool on: modelData[3]
                readonly property color accent: modelData[4]
                Layout.fillWidth: true; Layout.preferredWidth: 1
                height: 84; radius: 16
                color: on ? Qt.rgba(accent.r, accent.g, accent.b, 0.22) : (tm.containsMouse ? "#22efeaf8" : Theme.card)
                border.width: 1; border.color: on ? Qt.rgba(accent.r, accent.g, accent.b, 0.7) : "#14efeaf8"
                Behavior on color { ColorAnimation { duration: 150 } }
                Column {
                    x: 12; y: 12; width: parent.width - 24; spacing: 8
                    Rectangle {
                        width: 30; height: 30; radius: 10
                        color: tile.on ? tile.accent : "#3313121c"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Label { anchors.centerIn: parent; text: modelData[0]; color: tile.on ? Theme.bg : tile.accent; font.pixelSize: 15 }
                    }
                    Column {
                        width: parent.width; spacing: 0
                        Label { width: parent.width; text: modelData[1]; font.pixelSize: 12; elide: Text.ElideRight }
                        Label { width: parent.width; text: modelData[2]; color: tile.on ? tile.accent : Theme.muted; font.pixelSize: 10; font.weight: Font.Normal; elide: Text.ElideRight }
                    }
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[5]() }
            }
        }
    }

    RowLayout {
        width: parent.width; spacing: 12

        // ================= left column =================
        Column {
            Layout.preferredWidth: 1; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 12

            CcCard {
                title: "Sound"; icon: "\u{f057e}"
                // output
                RowLayout {
                    width: parent.width; spacing: 10
                    Rectangle {
                        width: 30; height: 30; radius: 10; color: om.containsMouse ? Theme.bgHover : "#3313121c"
                        Label { anchors.centerIn: parent; text: cc.sink && cc.sink.audio && cc.sink.audio.muted ? "\u{f075f}" : "\u{f057e}"; color: Theme.blue; font.pixelSize: 15 }
                        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.sink) cc.sink.audio.muted = !cc.sink.audio.muted }
                    }
                    Item {
                        Layout.fillWidth: true; height: 30
                        Slider { anchors.verticalCenter: parent.verticalCenter; width: parent.width; accent: Theme.blue
                                 value: cc.sink && cc.sink.audio ? Math.min(1, cc.sink.audio.volume) : 0
                                 onMoved: v => { if (cc.sink) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } } }
                    }
                    Label { text: cc.sink && cc.sink.audio ? Math.round(cc.sink.audio.volume * 100) + "%" : ""; color: Theme.fgDim; font.pixelSize: 11; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                }
                // mic
                RowLayout {
                    width: parent.width; spacing: 10
                    Rectangle {
                        width: 30; height: 30; radius: 10; color: mm.containsMouse ? Theme.bgHover : "#3313121c"
                        Label { anchors.centerIn: parent; text: cc.source && cc.source.audio && cc.source.audio.muted ? "\u{f036d}" : "\u{f036c}"; color: Theme.purple; font.pixelSize: 15 }
                        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (cc.source) cc.source.audio.muted = !cc.source.audio.muted }
                    }
                    Item {
                        Layout.fillWidth: true; height: 30
                        Slider { anchors.verticalCenter: parent.verticalCenter; width: parent.width; accent: Theme.purple
                                 value: cc.source && cc.source.audio ? Math.min(1, cc.source.audio.volume) : 0
                                 onMoved: v => { if (cc.source) cc.source.audio.volume = v } }
                    }
                    Label { text: cc.source && cc.source.audio ? Math.round(cc.source.audio.volume * 100) + "%" : ""; color: Theme.fgDim; font.pixelSize: 11; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                }
                // output devices
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: cc.sinks
                        Rectangle {
                            required property var modelData
                            readonly property bool cur: cc.sink && (cc.sink.id === modelData.id || (cc.sink.name === "headset_eq" && (modelData.name || "").indexOf("Fuxi") >= 0))
                            width: dl.implicitWidth + 26; height: 28; radius: 10
                            color: cur ? Qt.rgba(0.64, 0.54, 0.91, 0.2) : (dm.containsMouse ? "#22efeaf8" : "#3313121c")
                            border.width: cur ? 1 : 0; border.color: Theme.blue
                            Label { id: dl; anchors.centerIn: parent; text: (cur ? "\u{f012c} " : "") + cc.nice(modelData).slice(0, 20); color: cur ? Theme.blue : Theme.fgDim; font.pixelSize: 10 }
                            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (cur) return; if (SysState.fx.eq) SysState.fxToggle("eq"); Pipewire.preferredDefaultAudioSink = modelData } }
                        }
                    }
                }
                // EQ
                Rectangle { width: parent.width; height: 1; color: "#14efeaf8" }
                RowLayout {
                    width: parent.width; spacing: 6
                    Label { text: "\u{f1de}  EQ"; color: SysState.fx.eq ? Theme.cyan : Theme.muted; font.pixelSize: 11; Layout.rightMargin: 4 }
                    Repeater {
                        model: [["off", "Off"], ["flat", "Flat"], ["music", "Music"], ["games", "Games"], ["bass", "Bass"]]
                        Rectangle {
                            required property var modelData
                            readonly property bool cur: modelData[0] === "off" ? !SysState.fx.eq : (!!SysState.fx.eq && SysState.fx.preset === modelData[0])
                            Layout.fillWidth: true; height: 26; radius: 9
                            color: cur ? Theme.cyan : (em.containsMouse ? "#22efeaf8" : "#3313121c")
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Label { anchors.centerIn: parent; text: modelData[1]; color: cur ? Theme.bg : Theme.fgDim; font.pixelSize: 10 }
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

            CcCard {
                title: "Screens"; icon: "\u{f0379}"
                Repeater {
                    model: [["DP-1", "Main"], ["DP-2", "Side"]]
                    RowLayout {
                        required property var modelData
                        width: parent.width; spacing: 10
                        Rectangle {
                            width: 30; height: 30; radius: 10; color: "#3313121c"
                            Label { anchors.centerIn: parent; text: "\u{f00df}"; color: Theme.purple; font.pixelSize: 15 }
                        }
                        Label { text: modelData[1]; color: Theme.fgDim; font.pixelSize: 11; Layout.preferredWidth: 34 }
                        Item {
                            Layout.fillWidth: true; height: 30
                            Slider { anchors.verticalCenter: parent.verticalCenter; width: parent.width; accent: Theme.purple
                                     value: (cc.bright[modelData[0]] || 0) / 100
                                     onMoved: v => cc.setBright(modelData[0], Math.round(v * 100)) }
                        }
                        Label { text: (cc.bright[modelData[0]] || 0) + "%"; color: Theme.fgDim; font.pixelSize: 11; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
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
                title: "System"; icon: "\u{f04bc}"
                RowLayout {
                    width: parent.width; spacing: 8
                    MiniStat { icon: "\u{f0ee0}"; title: "CPU"; usage: Stats.d.cpu; temp: Stats.d.cpuTemp; extra: Stats.d.cpuFreq + " GHz"; accent: Theme.cyan }
                    MiniStat { icon: "\u{f08ae}"; title: "GPU"; usage: Stats.d.gpu; temp: Stats.d.gpuTemp; extra: Stats.d.gpuPower + " W"; accent: Theme.purple }
                    MiniStat { icon: "\u{f035b}"; title: "RAM"; usage: Stats.d.ram; extra: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB"; accent: Theme.blue }
                }
                RowLayout {
                    width: parent.width
                    Label { text: "\u{f0200}  " + (Stats.d.iface || "network"); color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true }
                    Label { text: "\u{f0045} " + cc.speed(Stats.d.netRx || 0); color: Theme.cyan; font.pixelSize: 10 }
                    Label { text: "   \u{f005d} " + cc.speed(Stats.d.netTx || 0); color: Theme.purple; font.pixelSize: 10 }
                }
            }

            CcCard {
                title: Notifs.count > 0 ? "Notifications · " + Notifs.count : "Notifications"; icon: "\u{f009a}"
                Column {
                    visible: Notifs.count === 0
                    width: parent.width; spacing: 4; topPadding: 4; bottomPadding: 8
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f0e1e}"; color: Theme.line; font.pixelSize: 26 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "You're all caught up"; color: Theme.muted; font.pixelSize: 11 }
                }
                ListView {
                    visible: Notifs.count > 0
                    width: parent.width
                    height: Math.min(contentHeight, 220)
                    clip: true; spacing: 6
                    verticalLayoutDirection: ListView.BottomToTop
                    model: Notifs.model
                    delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                }
                Rectangle {
                    visible: Notifs.count > 0
                    width: parent.width; height: 28; radius: 9
                    color: clrMouse.containsMouse ? "#22efeaf8" : "#3313121c"
                    Label { anchors.centerIn: parent; text: "\u{f0e1e}  Clear all"; color: Theme.fgDim; font.pixelSize: 10 }
                    MouseArea { id: clrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                }
            }

            CcCard {
                visible: SystemTray.items.values.length > 0 || Updates.total > 0
                RowLayout {
                    width: parent.width; spacing: 12
                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            width: 20; height: 20
                            IconImage { anchors.fill: parent; source: modelData.icon; opacity: trMouse.containsMouse ? 1 : 0.75 }
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
                        width: ul.implicitWidth + 22; height: 28; radius: 10
                        color: uMouse.containsMouse ? "#b5a2f2" : Theme.blue
                        Label { id: ul; anchors.centerIn: parent; text: "\u{f06b0}  Update " + Updates.total; color: Theme.bg; font.pixelSize: 10 }
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
                ["\u{f0100}", "Snip",      Theme.blue,   () => cc.go(["sh", "-c", "sleep 0.3; ~/.config/hypr/scripts/screenshot.sh region"])],
                ["\u{f0d52}", "Color",     Theme.purple, () => cc.go(["sh", "-c", "sleep 0.3; hyprpicker -a"])],
                ["\u{f014c}", "Clipboard", Theme.cyan,   () => cc.qs("clipboard")],
                ["\u{f0785}", "Emoji",     Theme.yellow, () => cc.qs("emoji")],
                ["\u{f02e9}", "Wallpaper", Theme.purple,  () => cc.qs("wallpaper")],
                ["\u{f0eb5}", "Games",     Theme.red,    () => cc.qs("games")],
                ["\u{f0493}", "Settings",  Theme.blue,   () => cc.qs("settings")]
            ]
            Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredWidth: 1; height: 58; radius: 14
                color: qm.containsMouse ? Qt.rgba(modelData[2].r, modelData[2].g, modelData[2].b, 0.16) : Theme.card
                border.width: 1; border.color: qm.containsMouse ? Qt.rgba(modelData[2].r, modelData[2].g, modelData[2].b, 0.5) : "#14efeaf8"
                Behavior on color { ColorAnimation { duration: 120 } }
                Column {
                    anchors.centerIn: parent; spacing: 5
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: modelData[2]; font.pixelSize: 17 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: Theme.fgDim; font.pixelSize: 9; font.weight: Font.Normal }
                }
                MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[3]() }
            }
        }
    }
}
