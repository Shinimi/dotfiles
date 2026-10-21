// Workspaces 1-4 of the main screen. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Pill {
    padding: 4
    Repeater {
        model: 4
        Rectangle {
            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            readonly property bool isActive: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)
            readonly property bool hasWindows: !!(ws && ws.toplevels && ws.toplevels.values.length > 0)
            width: isActive ? 30 : 22; height: 18; radius: 6
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            color: isActive ? Theme.blue : (wsMouse.containsMouse ? Theme.bgHover : "transparent")
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Label {
                anchors.centerIn: parent
                text: wsId
                color: isActive ? Theme.bg : (hasWindows ? Theme.fg : Theme.muted)
            }
            MouseArea {
                id: wsMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"])
            }
        }
    }
}
