// The bar (main screen): a tile in your window grid: same gap, rounding, glass and border as the windows.
//   left:   launcher · workspaces (numbers, white underline = current, scroll to switch)
//   middle: time (hover: date and weather, click: calendar)
//   right:  small icons for what's on right now (click to turn off) · control center · power
// A hairline under the middle of the bar pulses with the music. Volume changes show the pop-up in Osd.qml. Made by Claude.
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
    implicitHeight: 110                      // clicks only land on the bar (mask)
    visible: !PopupState.focusMode           // focus mode hides the bar and gives its space back
    exclusiveZone: PopupState.focusMode ? 0 : Theme.barBottom
    color: "transparent"
    mask: Region { item: bar }

    // ---------- state ----------
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    readonly property bool playing: !!(player && player.isPlaying)
    function ipc(target, fn) { Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", target, fn]) }
    function panel() { ipc("panel", "toggle") }
    property bool recording: false
    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    readonly property bool talking: !!(mic && mic.audio && !mic.audio.muted)
    Component.onCompleted: if (isMain) Stats.watchers += 1   // the bar's readout keeps the stats ticking every 2 s

    // ---------- the bar: no strip, just small things floating over the wallpaper ----------
    Rectangle {   // a soft fade from the top edge, only so the small text stays readable over any wallpaper
        width: parent.width; height: Theme.barBottom + 22
        gradient: Gradient { GradientStop { position: 0; color: "#8c000000" } GradientStop { position: 1; color: "#00000000" } }
    }
    Item {
        id: bar
        x: Settings.cur("gaps_out"); y: Theme.barTop
        width: parent.width - 2 * Settings.cur("gaps_out")
        height: Theme.barHeight

        // music pulse: one hairline under the middle of the bar that widens and brightens with the beat
        // (pulse.py listens to the speakers, never the mic). Only while music plays, never in games. Settings → Extras.
        property real beat: 0
        Process {
            running: win.isMain && win.playing && Settings.cur("music_pulse") !== false && !SysState.gameMode
            onRunningChanged: if (!running) bar.beat = 0
            command: ["python3", "-I", Quickshell.env("HOME") + "/.config/quickshell/bar/pulse.py"]
            stdout: SplitParser { onRead: l => bar.beat = parseFloat(l) || 0 }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            height: 1; radius: 1
            width: bar.beat > 0 ? mid.width * (0.15 + 0.85 * bar.beat) : 0
            color: "#ffffff"; opacity: 0.18 + 0.7 * bar.beat
            Behavior on width { NumberAnimation { duration: 70 } }
        }

        Launcher { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }   // left: just the logo

        Row {   // middle: workspace dots · what's playing · the time
            id: mid
            anchors.centerIn: parent; spacing: 12
            Loader {   // Hyprland's workspace dots, or Niri's
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: Niri.active ? niriDots : hyprDots
                Component { id: hyprDots; Workspaces { dots: true } }
                Component { id: niriDots; NiriWorkspaces { screenName: "DP-1" } }
            }
            Sep {}
            Row {   // the machine at a glance: CPU load, CPU temperature, RAM in use
                anchors.verticalCenter: parent.verticalCenter; spacing: 14
                Repeater {
                    model: [["\u{f035b}", (Stats.d.cpu || 0) + "%", false], ["\u{f050f}", (Stats.d.cpuTemp || 0) + "°C", (Stats.d.cpuTemp || 0) >= 85],
                            ["\u{f061a}", (Stats.d.ramUsed || 0).toFixed(1) + " GiB", (Stats.d.ram || 0) >= 90]]
                    Row {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Label { text: modelData[0]; color: "#8a8a8a"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.CurveRendering }   // grey edges, no colour fringe on small icons
                        Label { text: modelData[1]; color: modelData[2] ? "#ffffff" : "#cfcfcf"; font.pixelSize: 11; font.bold: modelData[2]; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            Sep {}
            ClockPill { id: clockPill; anchors.verticalCenter: parent.verticalCenter }   // hover: date and weather
        }

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

    component Sep: Rectangle { anchors.verticalCenter: parent ? parent.verticalCenter : undefined; width: 3; height: 3; radius: 2; color: "#4a4a4a" }

    // open panels from keybinds / scripts:  qs -p ~/.config/quickshell/bar ipc call bar calendar  (main screen only)
    LazyLoader {
        active: win.isMain
        IpcHandler {
            target: "bar"
            function calendar(): void { clockPill.popup.toggle() }
            function recording(on: bool): void { win.recording = on }   // rec.sh tells the bar
            function fx(): void { SysState.refresh() }                   // audio-fx changes tell the bar
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
            function status(): string { return "cal=" + clockPill.popup.visible + " pow=" + powerPill.popup.visible }
        }
    }
}
