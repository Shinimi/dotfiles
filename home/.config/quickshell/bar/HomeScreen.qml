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
    onVisibleChanged: if (visible) { PopupState.current = root; month = new Date(); now = new Date(); ScreenTime.loadWeek(); MusicStats.loadWeek() }
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
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.now, "dddd, d MMMM")
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
                            Text { width: parent.width; elide: Text.ElideRight; text: root.player ? root.player.trackTitle : "Nothing playing"
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

            // weather: today, then the week
            Card {
                id: wcard
                title: "weather · " + (Weather.place || "")
                Layout.preferredWidth: 380; Layout.fillHeight: true
                MouseArea { anchors.fill: parent }
                readonly property var today: Weather.week[Qt.formatDate(root.now, "yyyy-MM-dd")] || null
                Column {
                    anchors.fill: parent; spacing: 12
                    Row {
                        spacing: 14
                        Text { text: Weather.icon; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 44; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { text: Weather.ready ? Weather.temp + "°" : "–"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 34; font.bold: true }
                            Text { text: Weather.desc + " · feels " + Weather.feels + "°"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                        }
                    }
                    Row {   // the next 7 days
                        width: parent.width
                        Repeater {
                            model: 7
                            Column {
                                required property int index
                                readonly property date d: { const x = new Date(root.now); x.setDate(x.getDate() + index); return x }
                                readonly property var w: Weather.week[Qt.formatDate(d, "yyyy-MM-dd")] || null
                                width: parent.width / 7; spacing: 4
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Today" : Qt.formatDate(parent.d, "ddd")
                                       color: index === 0 ? "#ffffff" : Theme.muted; font.family: Theme.font; font.pixelSize: 9; font.bold: index === 0 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.w ? Weather.wmoIcon(parent.w.code, false) : ""; color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 16 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.w ? parent.w.max + "°" : ""; color: "#e8e8e8"; font.family: Theme.font; font.pixelSize: 11; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.w ? parent.w.min + "°" : ""; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                            }
                        }
                    }
                    Text { width: parent.width; wrapMode: Text.WordWrap; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 10
                           text: wcard.today ? (wcard.today.rain >= 50 ? "Rain likely today (" + wcard.today.rain + "%)" : "Dry today") + "  ·  sunset " + wcard.today.sunset : "" }
                }
            }

            // calendar
            Card {
                title: Qt.formatDate(root.month, "MMMM yyyy")
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
                        model: ["M", "T", "W", "T", "F", "S", "S"]
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

            // screen time / music (switch at the top right)
            Card {
                id: stCard
                property bool music: !ScreenTime.enabled
                visible: ScreenTime.enabled || MusicStats.enabled
                title: music ? "music · this week" : "screen time"
                Layout.preferredWidth: 300; Layout.fillHeight: true
                MouseArea { anchors.fill: parent }
                Row {
                    visible: ScreenTime.enabled && MusicStats.enabled
                    anchors.right: parent.right; y: -28; spacing: 4
                    Repeater {
                        model: [["Apps", false], ["Music", true]]
                        Rectangle {
                            required property var modelData
                            readonly property bool on: stCard.music === modelData[1]
                            width: tabT.implicitWidth + 16; height: 20; radius: 10
                            color: on ? Theme.on : (tabM.containsMouse ? "#1fffffff" : "transparent")
                            Text { id: tabT; anchors.centerIn: parent; text: parent.modelData[0]; color: parent.on ? Theme.onText : Theme.muted
                                   font.family: Theme.font; font.pixelSize: 10; font.bold: parent.on }
                            MouseArea { id: tabM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: stCard.music = parent.modelData[1] }
                        }
                    }
                }
                Column {
                    visible: !stCard.music
                    anchors.fill: parent; spacing: 10
                    Row {
                        spacing: 10
                        Text { text: ScreenTime.fmt(ScreenTime.total(ScreenTime.today)); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 26; font.bold: true }
                        Text { anchors.baseline: parent.children[0].baseline; text: "today"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Repeater {
                        model: ScreenTime.top(ScreenTime.today, 5)
                        Column {
                            id: st
                            required property var modelData
                            readonly property real share: modelData.secs / Math.max(1, ScreenTime.top(ScreenTime.today, 1)[0].secs)
                            width: parent.width; spacing: 4
                            Item {
                                width: parent.width; height: 14
                                Text { width: parent.width - 60; elide: Text.ElideRight; text: st.modelData.label; color: "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11 }
                                Text { anchors.right: parent.right; text: ScreenTime.fmt(st.modelData.secs); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            Rectangle {
                                width: parent.width; height: 4; radius: 2; color: "#1fffffff"
                                Rectangle { width: Math.max(4, parent.width * st.share); height: 4; radius: 2; color: Theme.on }
                            }
                        }
                    }
                    Text { visible: ScreenTime.total(ScreenTime.today) === 0; text: "Nothing yet today"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                }
                Text {
                    visible: !stCard.music
                    anchors.bottom: parent.bottom; anchors.bottomMargin: -2
                    text: "Last 7 days  " + ScreenTime.fmt(ScreenTime.total(ScreenTime.weekAll))
                          + (ScreenTime.top(ScreenTime.weekAll, 1).length ? "  ·  most: " + ScreenTime.top(ScreenTime.weekAll, 1)[0].label : "")
                    width: parent.width; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10
                }
                // ---- music: top artists with bars, then top songs
                Column {
                    visible: stCard.music
                    anchors.fill: parent; spacing: 7
                    Row {
                        spacing: 10
                        Text { text: MusicStats.fmt(MusicStats.total(MusicStats.weekAll)); color: "#ffffff"; font.family: Theme.font; font.pixelSize: 26; font.bold: true }
                        Text { anchors.baseline: parent.children[0].baseline; text: "listened"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Repeater {
                        model: MusicStats.artists(MusicStats.weekAll, 3)
                        Column {
                            id: ar
                            required property var modelData
                            required property int index
                            readonly property real share: modelData.secs / Math.max(1, MusicStats.artists(MusicStats.weekAll, 1)[0].secs)
                            width: parent.width; spacing: 4
                            Item {
                                width: parent.width; height: 14
                                Text { width: parent.width - 60; elide: Text.ElideRight; text: (ar.index + 1) + "  " + ar.modelData.name; color: "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11; font.bold: ar.index === 0 }
                                Text { anchors.right: parent.right; text: MusicStats.fmt(ar.modelData.secs); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                            }
                            Rectangle {
                                width: parent.width; height: 4; radius: 2; color: "#1fffffff"
                                Rectangle { width: Math.max(4, parent.width * ar.share); height: 4; radius: 2; color: Theme.on }
                            }
                        }
                    }
                    Text { topPadding: 3; visible: MusicStats.total(MusicStats.weekAll) > 0; text: "TOP SONGS"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.4 }
                    Repeater {
                        model: MusicStats.songs(MusicStats.weekAll, 3)
                        Item {
                            required property var modelData
                            width: parent.width; height: 15
                            Text { width: parent.width - 50; elide: Text.ElideRight; textFormat: Text.StyledText
                                   text: parent.modelData.title.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "  <font color='#8a8a8a'>" + parent.modelData.artist.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</font>"
                                   color: "#dcdcdc"; font.family: Theme.font; font.pixelSize: 11 }
                            Text { anchors.right: parent.right; text: MusicStats.fmt(parent.modelData.secs); color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        }
                    }
                    Text { visible: MusicStats.total(MusicStats.weekAll) === 0; width: parent.width; wrapMode: Text.WordWrap
                           text: "Nothing yet. Play something on Spotify and it shows up here."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                }
                Text {
                    visible: stCard.music
                    anchors.bottom: parent.bottom; anchors.bottomMargin: -2
                    text: "Today  " + MusicStats.fmt(MusicStats.total(MusicStats.today)) + "  ·  " + Object.keys(MusicStats.today).length + " songs"
                    width: parent.width; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10
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
                        icon: "\u{f057e}"; text: "Volume"
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
                    Text { visible: Notifs.count === 0; anchors.centerIn: parent; text: "All caught up"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    ListView {
                        visible: Notifs.count > 0; anchors.fill: parent; clip: true; spacing: 6
                        verticalLayoutDirection: ListView.BottomToTop; model: Notifs.model
                        delegate: NotifCard { required property var modelData; notif: modelData; width: ListView.view ? ListView.view.width : 300 }
                    }
                }
            }
        }

        // ---------- session: lock and sleep right here, the rest in the power menu ----------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: cards.y + cards.height + 50; spacing: 12
            Repeater {
                model: [["\u{f033e}", "Lock", () => root.go(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"])],
                        ["\u{f0904}", "Sleep", () => root.go(["systemctl", "suspend"])],
                        ["\u{f0425}", "Power…", () => { root.visible = false; PowerMenu.toggle() }]]
                Rectangle {
                    required property var modelData
                    width: sl.implicitWidth + 58; height: 46; radius: 23
                    color: sb.containsMouse ? "#ececec" : "#cc141414"; border.width: 1; border.color: sb.containsMouse ? "#ececec" : "#30ffffff"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        anchors.centerIn: parent; spacing: 10
                        Text { text: modelData[0]; font.family: Theme.font; font.pixelSize: 16; color: sb.containsMouse ? "#0b0b0b" : "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: sl; text: modelData[1]; font.family: Theme.font; font.pixelSize: 12; font.bold: true; color: sb.containsMouse ? "#0b0b0b" : "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: sb; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[2]() }
                }
            }
        }
    }
}
