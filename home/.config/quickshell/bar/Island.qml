// Dynamic island: one small black pill at the top centre (time + what's going on).
// Hover it and it grows into the full bar (launcher, workspaces, clock, media, status, power).
// When the song changes or the volume moves it briefly morphs to show that. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 64                       // room to grow on peeks; clicks only land on the pill (mask)
    exclusiveZone: Theme.barHeight + 4
    color: "transparent"
    mask: Region { item: island }

    // ---------- state ----------
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    readonly property bool playing: !!(player && player.isPlaying)
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    readonly property bool popupOpen: clockPill.popup.visible || statusPill.popup.visible || mediaPill.popup.visible || powerPill.popup.visible
    property bool hoverHeld: false           // hovered long enough to count (no flicker when passing by)
    Timer { id: enterDelay; interval: 90; onTriggered: win.hoverHeld = true }
    Timer { id: leaveDelay; interval: 420; onTriggered: win.hoverHeld = false }
    readonly property bool expanded: hoverHeld || popupOpen
    property string peek: ""                 // "", "media", "volume"
    Timer { id: peekTimer; interval: 3200; onTriggered: win.peek = "" }
    function showPeek(kind) { if (!armed || expanded) return; peek = kind; peekTimer.restart() }
    readonly property string mode: expanded ? "full" : peek !== "" ? peek : "compact"
    property bool armed: false               // no peeks while everything starts up
    Timer { running: true; interval: 3000; onTriggered: win.armed = true }

    Connections { target: win.player; function onTrackTitleChanged() { if (win.player && win.player.trackTitle) win.showPeek("media") } }
    Connections {
        target: win.sink ? win.sink.audio : null
        function onVolumeChanged() { win.showPeek("volume") }
        function onMutedChanged() { win.showPeek("volume") }
    }

    // ---------- the pill ----------
    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 6
        readonly property Item cur: win.mode === "full" ? full : win.mode === "media" ? mediaPeek : win.mode === "volume" ? volPeek : compact
        width: cur.implicitWidth + (win.mode === "full" ? 8 : 30)
        height: win.mode === "media" ? 50 : Theme.barHeight
        radius: win.mode === "media" ? 20 : height / 2
        color: Theme.island
        border.width: 1; border.color: "#16ffffff"
        clip: true
        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        Behavior on radius { NumberAnimation { duration: 300 } }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { leaveDelay.stop(); enterDelay.restart() }
                else { enterDelay.stop(); leaveDelay.restart() }
            }
        }

        // compact: workspace · time · music bars · notification dot
        Row {
            id: compact
            anchors.centerIn: parent; spacing: 10
            opacity: win.mode === "compact" ? 1 : 0; enabled: opacity > 0.5
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; radius: 10; color: Theme.on
                Label { anchors.centerIn: parent; text: win.wsId; color: Theme.onText; font.pixelSize: 10; font.weight: Font.Bold }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, Settings.cur("clock_12h") ? "h:mm AP" : "HH:mm")
                color: "#ffffff"; font.weight: Font.Bold; font.pixelSize: 13
            }
            MusicBars { anchors.verticalCenter: parent.verticalCenter; visible: win.playing; running: win.playing && win.mode === "compact" }
            Rectangle {
                visible: (Notifs.count > 0 && !Notifs.dnd) || SysState.gameMode
                anchors.verticalCenter: parent.verticalCenter
                width: 6; height: 6; radius: 3; color: Notifs.count > 0 && !Notifs.dnd ? Theme.red : Theme.fgDim
            }
        }

        // peek: song
        Row {
            id: mediaPeek
            anchors.centerIn: parent; spacing: 12
            opacity: win.mode === "media" ? 1 : 0; enabled: false
            Behavior on opacity { NumberAnimation { duration: 200 } }
            ClippingRectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34; radius: 9; color: Theme.bgAlt
                Image { anchors.fill: parent; source: win.player ? (win.player.trackArtUrl || "") : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true
                        sourceSize.width: 68; sourceSize.height: 68 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 1
                Label { text: win.player ? win.player.trackTitle : ""; font.pixelSize: 12; font.weight: Font.Bold; elide: Text.ElideRight; width: Math.min(implicitWidth, 300) }
                Label { text: win.player ? win.player.trackArtist : ""; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal; elide: Text.ElideRight; width: Math.min(implicitWidth, 300) }
            }
            MusicBars { anchors.verticalCenter: parent.verticalCenter; running: win.playing && win.mode === "media" }
        }

        // peek: volume
        Row {
            id: volPeek
            readonly property real v: win.sink && win.sink.audio ? Math.min(1, win.sink.audio.volume) : 0
            readonly property bool m: !!(win.sink && win.sink.audio && win.sink.audio.muted)
            anchors.centerIn: parent; spacing: 12
            opacity: win.mode === "volume" ? 1 : 0; enabled: false
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Label { anchors.verticalCenter: parent.verticalCenter; text: volPeek.m ? "\u{f075f}" : "\u{f057e}"; color: volPeek.m ? Theme.muted : Theme.fg; font.pixelSize: 14 }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 150; height: 5; radius: 3; color: "#26ffffff"
                Rectangle { height: parent.height; radius: 3; width: parent.width * (volPeek.m ? 0 : volPeek.v); color: Theme.on
                            Behavior on width { NumberAnimation { duration: 90 } } }
            }
            Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(volPeek.v * 100); width: 22; horizontalAlignment: Text.AlignRight; font.pixelSize: 11 }
        }

        // full: everything
        Row {
            id: full
            anchors.centerIn: parent; spacing: 4
            opacity: win.mode === "full" ? 1 : 0; enabled: opacity > 0.5
            Behavior on opacity { NumberAnimation { duration: win.mode === "full" ? 260 : 120 } }
            Launcher { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { anchors.verticalCenter: parent.verticalCenter }
            Sep {}
            ClockPill { id: clockPill; anchors.verticalCenter: parent.verticalCenter }
            Sep { visible: mediaPill.visible }
            MediaPill { id: mediaPill; anchors.verticalCenter: parent.verticalCenter }
            Sep {}
            StatusPill { id: statusPill; anchors.verticalCenter: parent.verticalCenter }
            PowerButton { id: powerPill; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    component Sep: Rectangle { anchors.verticalCenter: parent ? parent.verticalCenter : undefined; width: 1; height: 14; color: "#1fffffff" }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // open panels from keybinds / scripts:  qs -p ~/.config/quickshell/bar ipc call bar calendar
    IpcHandler {
        target: "bar"
        function calendar(): void { clockPill.popup.toggle() }
        function stats(): void { statusPill.popup.toggle() }
        function volume(): void { statusPill.popup.toggle() }
        function power(): void { powerPill.popup.toggle() }
        function media(): void { mediaPill.popup.toggle() }
        function notifications(): void { statusPill.popup.toggle() }
        function control(): void { statusPill.popup.toggle() }
        function expand(): void { win.hoverHeld = !win.hoverHeld }
        function dnd(on: bool): void { Notifs.dnd = on }
        function timer(minutes: int): void { Timers.resetTimer(); Timers.setMinutes(minutes); Timers.toggleTimer() }
        function timerReset(): void { Timers.resetTimer() }
        function clearNotifications(): void { Notifs.clearAll() }
        function status(): string { return "cal=" + clockPill.popup.visible + " cc=" + statusPill.popup.visible + " pow=" + powerPill.popup.visible + " mode=" + win.mode }
    }
}
