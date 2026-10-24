// The bar (main screen): a tile in your window grid: same gap, rounding, glass and border as the windows.
//   left:   launcher · workspaces (numbers, white underline = current, scroll to switch)
//   middle: time (hover: date and weather, click: calendar)
//   right:  small icons for what's on right now (click to turn off) · control center · power
// When the song changes, a small card drops out under the main screen's bar for a moment. Volume changes show
// the pop-up in Osd.qml. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property bool isMain: modelData.name === "DP-1"
    anchors { top: true; left: true; right: true }
    implicitHeight: 110                      // room for the song card; clicks only land on the bar (mask)
    visible: !PopupState.focusMode           // focus mode hides the bar and gives its space back
    exclusiveZone: PopupState.focusMode ? 0 : Theme.barBottom
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
    property bool recording: false
    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    readonly property bool talking: !!(mic && mic.audio && !mic.audio.muted)

    // ---------- the bar ----------
    Rectangle {
        id: bar
        // lined up with your windows: same outer gap, same rounding, same glass and border
        x: Settings.cur("gaps_out"); y: Theme.barTop
        width: parent.width - 2 * Settings.cur("gaps_out")
        height: Theme.barHeight
        radius: Settings.cur("rounding")
        color: Qt.rgba(0.06, 0.06, 0.06, 0.88)
        border.width: 1; border.color: "#2effffff"

        Row {   // left: launcher + workspaces
            anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Launcher { anchors.verticalCenter: parent.verticalCenter }
            Sep {}
            Workspaces { anchors.verticalCenter: parent.verticalCenter }
        }

        ClockPill { id: clockPill; anchors.centerIn: parent }   // middle: the time (hover: date and weather)

        Row {   // right: what's on right now (only while it's on), then control center + power
            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Pill {   // recording: a red dot and the time; click to stop
                id: recPill
                visible: win.recording; anchors.verticalCenter: parent.verticalCenter
                property int secs: 0
                Timer { running: win.recording; interval: 1000; repeat: true; onTriggered: recPill.secs++ }
                onVisibleChanged: secs = 0
                Rectangle { width: 9; height: 9; radius: 5; color: "#e05252"; anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            SequentialAnimation on opacity { running: win.recording; loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700 } NumberAnimation { to: 1; duration: 700 } } }
                Label { text: Math.floor(recPill.secs / 60) + ":" + String(recPill.secs % 60).padStart(2, "0"); color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/rec.sh"])
            }
            Pill {   // push to talk: dim mic = muted, white = you're talking
                visible: !!Settings.cur("ptt"); anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 28; active: win.talking
                Label { text: win.talking ? "\u{f036c}" : "\u{f036d}"; color: win.talking ? "#ffffff" : "#6a6a6a"; font.pixelSize: 13 }
                onClicked: Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "settings", "open", "sound"])
            }
            Repeater {   // click one to turn it off
                model: [[Notifs.dnd, "\u{f009b}", "Do not disturb", () => { Notifs.dnd = false }],
                        [SysState.gameMode, "\u{f0eb5}", "Game mode", () => { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/gamemode.sh", "off"]); SysState.gameMode = false }],
                        [SysState.awake, "\u{f0176}", "Keep awake", () => SysState.toggleAwake()],
                        [!!Settings.cur("mono_mode"), "\u{f0197}", "Monochrome", () => Settings.setNow("mono_mode", false)],
                        [SysState.night, "\u{f0594}", "Night light", () => SysState.toggleNight()]].filter(x => x[0])
                Pill {
                    required property var modelData
                    implicitWidth: 28; anchors.verticalCenter: parent.verticalCenter
                    Label { text: modelData[1]; color: "#cfcfcf"; font.pixelSize: 13 }
                    onClicked: modelData[3]()
                }
            }
            PrivacyPill { anchors.verticalCenter: parent.verticalCenter }
            Pill {   // only when the mouse needs charging
                visible: Battery.low; anchors.verticalCenter: parent.verticalCenter
                Label { text: Battery.icon + " " + Battery.percent + "%"; color: "#ffffff"; font.pixelSize: 12 }
                onClicked: win.panel()
            }
            Sep {}
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
        width: mediaPeek.implicitWidth + 28; height: 54; radius: 18
        y: win.peek !== "" ? bar.y + bar.height + 6 : bar.y + 4
        opacity: win.peek !== "" ? 1 : 0
        scale: win.peek !== "" ? 1 : 0.9
        color: "#f00b0b0b"; border.width: 1; border.color: "#14ffffff"
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
            function recording(on: bool): void { win.recording = on }   // rec.sh tells the bar
            function power(): void { powerPill.popup.toggle() }
            function control(): void { win.panel() }
            function notifications(): void { win.panel() }
            function stats(): void { win.panel() }
            function focus(on: bool): void { PopupState.focusMode = on }
            function dnd(on: bool): void { Notifs.dnd = on }
            function gameSummary(): void { Notifs.summary() }
            function timer(minutes: int): void { Timers.resetTimer(); Timers.setMinutes(minutes); Timers.toggleTimer() }
            function timerReset(): void { Timers.resetTimer() }
            function clearNotifications(): void { Notifs.clearAll() }
            function status(): string { return "cal=" + clockPill.popup.visible + " pow=" + powerPill.popup.visible + " peek=" + win.peek }
        }
    }
}
