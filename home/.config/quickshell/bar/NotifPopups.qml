// Notification pop-ups, top-right under the bar. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var screen
    visible: Notifs.popups.length > 0
    anchors { top: true; right: true }
    margins.top: Theme.barHeight + 10
    margins.right: 10
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsbar-notifications"
    color: "transparent"
    implicitWidth: 360
    implicitHeight: Math.max(1, stack.implicitHeight)
    Column {
        id: stack
        width: parent.width; spacing: 8
        Repeater {
            model: Notifs.popups
            NotifCard { required property var modelData; notif: modelData; popup: true }
        }
    }
}
