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

    // three floating glass islands (left · centre · right); Hyprland blurs only behind them
    component Island: Rectangle {
        default property alias items: islandRow.data
        anchors.top: parent.top; anchors.topMargin: 6
        height: Theme.barHeight
        width: islandRow.implicitWidth + 8
        radius: height / 2
        color: Theme.barBg
        border.width: 1; border.color: Theme.glassLine
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Row { id: islandRow; anchors.centerIn: parent; spacing: 2 }
    }

    Island {
        anchors.left: parent.left; anchors.leftMargin: 10
        Launcher {}
        Workspaces {}
    }
    Island {
        anchors.horizontalCenter: parent.horizontalCenter
        ClockPill { id: clockPill }
    }
    Island {
        anchors.right: parent.right; anchors.rightMargin: 10
        MediaPill { id: mediaPill }
        StatusPill { id: statusPill }
        PowerButton { id: powerPill }
    }

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
        function dnd(on: bool): void { Notifs.dnd = on }
        function timer(minutes: int): void { Timers.resetTimer(); Timers.setMinutes(minutes); Timers.toggleTimer() }
        function timerReset(): void { Timers.resetTimer() }
        function clearNotifications(): void { Notifs.clearAll() }
        function status(): string { return "cal=" + clockPill.popup.visible + " cc=" + statusPill.popup.visible + " pow=" + powerPill.popup.visible }
    }
}
