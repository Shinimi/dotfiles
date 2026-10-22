// The bar (main screen): one see-through glass strip with rounded corners.
//   left:   launcher · workspaces
//   middle: time · date · weather
//   right:  control center · power
// When the song changes, a small card drops out under the main screen's bar for a moment. Volume changes show
// nothing on purpose. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property bool isMain: modelData.name === "DP-1"
    anchors { top: true; left: true; right: true }
    implicitHeight: 110                      // room for the song card; clicks only land on the bar (mask)
    visible: !PopupState.focusMode           // focus mode hides the bar and gives its space back
    exclusiveZone: PopupState.focusMode ? 0 : Theme.barHeight + 6
    color: "transparent"
    mask: Region { item: bar }

    // ---------- state ----------
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    readonly property bool playing: !!(player && player.isPlaying)
    property string peek: ""                 // "" or "media"
    Timer { id: peekTimer; interval: 2600; onTriggered: win.peek = "" }
    function showPeek(kind) { if (!armed || !isMain || popupOpen || !Settings.cur("island_peeks")) return; peek = kind; peekTimer.restart() }
    readonly property bool popupOpen: clockPill.popup.visible || powerPill.popup.visible
    property bool armed: false               // no cards while everything starts up
    Timer { running: true; interval: 3000; onTriggered: win.armed = true }
    Connections { target: win.player; function onTrackTitleChanged() { if (win.player && win.player.trackTitle) win.showPeek("media") } }
    function ipc(target, fn) { Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", target, fn]) }
    function panel() { ipc("panel", "toggle") }

    // ---------- the bar ----------
    Rectangle {
        id: bar
        x: 10; y: 8
        width: parent.width - 20
        height: Theme.barHeight
        radius: 10
        color: Theme.mix(Qt.rgba(0.04, 0.04, 0.04, 0.45), Theme.tint, 0.10 * Theme.tintOn)   // see-through glass
        border.width: 1; border.color: "#1cffffff"

        Row {   // left: launcher + workspaces
            anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Launcher { anchors.verticalCenter: parent.verticalCenter }
            Sep {}
            Workspaces { anchors.verticalCenter: parent.verticalCenter }
        }

        ClockPill { id: clockPill; anchors.centerIn: parent }   // middle: time · date · weather

        Row {   // right: control center + power, nothing else
            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            StatusPill { anchors.verticalCenter: parent.verticalCenter }
            PowerButton { id: powerPill; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    component Sep: Rectangle { anchors.verticalCenter: parent ? parent.verticalCenter : undefined; width: 1; height: 14; color: "#1fffffff" }

    // ---------- song card (main screen only) ----------
    Rectangle {
        id: drop
        visible: win.isMain && opacity > 0.01
        anchors.horizontalCenter: parent.horizontalCenter
        width: mediaPeek.implicitWidth + 28; height: 50; radius: 10
        y: win.peek !== "" ? bar.y + bar.height + 6 : bar.y + 4
        opacity: win.peek !== "" ? 1 : 0
        scale: win.peek !== "" ? 1 : 0.9
        color: Theme.mix(Qt.rgba(0.04, 0.04, 0.04, 0.85), Theme.tint, 0.10 * Theme.tintOn); border.width: 1; border.color: "#1cffffff"
        Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Row {
            id: mediaPeek
            anchors.centerIn: parent; spacing: 12
            ClippingRectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34; radius: 6; color: Theme.bgAlt
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
    }

    // open panels from keybinds / scripts:  qs -p ~/.config/quickshell/bar ipc call bar calendar  (main screen only)
    LazyLoader {
        active: win.isMain
        IpcHandler {
            target: "bar"
            function calendar(): void { clockPill.popup.toggle() }
            function power(): void { powerPill.popup.toggle() }
            function control(): void { win.panel() }
            function notifications(): void { win.panel() }
            function stats(): void { win.panel() }
            function focus(on: bool): void { PopupState.focusMode = on }
            function dnd(on: bool): void { Notifs.dnd = on }
            function timer(minutes: int): void { Timers.resetTimer(); Timers.setMinutes(minutes); Timers.toggleTimer() }
            function timerReset(): void { Timers.resetTimer() }
            function clearNotifications(): void { Notifs.clearAll() }
            function status(): string { return "cal=" + clockPill.popup.visible + " pow=" + powerPill.popup.visible + " peek=" + win.peek }
        }
    }
}
