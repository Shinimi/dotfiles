// Notification pop-ups, top-right under the bar. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var modelData
    screen: modelData
    visible: Notifs.popups.count > 0
    readonly property bool center: Settings.cur("notif_center")
    anchors { top: true; right: !center }
    margins.top: Theme.barHeight + 10
    margins.right: center ? 0 : 10
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
            NotifCard {
                required property int nid
                notif: Notifs.notifById(nid)
                popup: true
                visible: notif !== null
            }
        }
    }
}
