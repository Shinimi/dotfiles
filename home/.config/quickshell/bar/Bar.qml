// The bar. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + 6
    exclusiveZone: Theme.barHeight + 4
    color: "transparent"

    Item {
        anchors.fill: parent
        anchors.topMargin: 6; anchors.leftMargin: 10; anchors.rightMargin: 10

        Row {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Launcher {}
            Workspaces {}
        }
        ClockPill { id: clockPill; anchors.centerIn: parent }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            MediaPill { id: mediaPill }
            UpdatesPill {}
            StatsPill { id: statsPill }
            VolumePill { id: volumePill }
            TrayNotify { id: trayPill }
            PowerButton { id: powerPill }
        }
    }

    // open panels from keybinds / scripts:  qs -p ~/.config/quickshell/bar ipc call bar calendar
    IpcHandler {
        target: "bar"
        function calendar(): void { clockPill.popup.toggle() }
        function stats(): void { statsPill.popup.toggle() }
        function volume(): void { volumePill.popup.toggle() }
        function power(): void { powerPill.popup.toggle() }
        function media(): void { mediaPill.popup.toggle() }
        function notifications(): void { trayPill.popup.toggle() }
        function clearNotifications(): void { Notifs.clearAll() }
        function setVolume(v: real): string { volumePill.sink.audio.volume = v; return "set " + v + " -> " + volumePill.sink.audio.volume }
        function status(): string { return "cal=" + clockPill.popup.visible + " stats=" + statsPill.popup.visible + " vol=" + volumePill.popup.visible + " pow=" + powerPill.popup.visible }
    }
}
