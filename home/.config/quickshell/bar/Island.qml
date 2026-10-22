// Island bar: one black glass pill at the top centre with everything (launcher, workspaces,
// clock, media, status, power). When the song changes or the volume moves, a small card drops
// out under it for a moment. Made by Claude.
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
    implicitHeight: 104                      // room for the drop-down card; clicks only land on the pill (mask)
    property bool focusMode: false           // focus mode hides the bar and gives its space back
    visible: !focusMode
    exclusiveZone: focusMode ? 0 : Theme.barHeight + 4
    color: "transparent"
    mask: Region { item: island }

    // ---------- state ----------
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    readonly property bool playing: !!(player && player.isPlaying)
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    property string peek: ""                 // "", "media", "volume"
    Timer { id: peekTimer; interval: 2600; onTriggered: win.peek = "" }
    function showPeek(kind) { if (!armed || popupOpen || !Settings.cur("island_peeks")) return; peek = kind; peekTimer.restart() }
    readonly property bool popupOpen: clockPill.popup.visible || statusPill.popup.visible || mediaPill.popup.visible || powerPill.popup.visible
    property bool armed: false               // no peeks while everything starts up
    Timer { running: true; interval: 3000; onTriggered: win.armed = true }

    Connections { target: win.player; function onTrackTitleChanged() { if (win.player && win.player.trackTitle) win.showPeek("media") } }
    Connections {
        target: win.sink ? win.sink.audio : null
        function onVolumeChanged() { win.showPeek("volume") }
        function onMutedChanged() { win.showPeek("volume") }
    }

    // ---------- drop-down card (song / volume) ----------
    Rectangle {
        id: drop
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property Item cur: win.peek === "volume" ? volPeek : mediaPeek
        width: cur.implicitWidth + 28; height: win.peek === "media" ? 50 : 36; radius: 18
        y: win.peek !== "" ? island.y + island.height + 6 : island.y + 4
        opacity: win.peek !== "" ? 1 : 0
        scale: win.peek !== "" ? 1 : 0.85
        visible: opacity > 0.01
        color: Theme.island; border.width: 1; border.color: Theme.glassLine
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        // peek: song
        Row {
            id: mediaPeek
            anchors.centerIn: parent; spacing: 12
            visible: win.peek !== "volume"
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
            MusicBars { anchors.verticalCenter: parent.verticalCenter; running: win.playing && win.peek === "media" }
        }

        // peek: volume
        Row {
            id: volPeek
            readonly property real v: win.sink && win.sink.audio ? Math.min(1, win.sink.audio.volume) : 0
            readonly property bool m: !!(win.sink && win.sink.audio && win.sink.audio.muted)
            anchors.centerIn: parent; spacing: 12
            visible: win.peek === "volume"
            Label { anchors.verticalCenter: parent.verticalCenter; text: volPeek.m ? "\u{f075f}" : "\u{f057e}"; color: volPeek.m ? Theme.muted : Theme.fg; font.pixelSize: 14 }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 150; height: 5; radius: 3; color: "#26ffffff"
                Rectangle { height: parent.height; radius: 3; width: parent.width * (volPeek.m ? 0 : volPeek.v); color: Theme.on
                            Behavior on width { NumberAnimation { duration: 90 } } }
            }
            Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(volPeek.v * 100); width: 22; horizontalAlignment: Text.AlignRight; font.pixelSize: 11 }
        }

    }

    // ---------- the pill ----------
    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: 6
        width: full.implicitWidth + 8
        height: Theme.barHeight
        radius: height / 2
        color: Theme.island
        border.width: 1; border.color: Theme.glassLine
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        // full: everything
        Row {
            id: full
            anchors.centerIn: parent; spacing: 4
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
        function focus(on: bool): void { win.focusMode = on }
        function dnd(on: bool): void { Notifs.dnd = on }
        function timer(minutes: int): void { Timers.resetTimer(); Timers.setMinutes(minutes); Timers.toggleTimer() }
        function timerReset(): void { Timers.resetTimer() }
        function clearNotifications(): void { Notifs.clearAll() }
        function status(): string { return "cal=" + clockPill.popup.visible + " cc=" + statusPill.popup.visible + " pow=" + powerPill.popup.visible + " peek=" + win.peek }
    }
}
