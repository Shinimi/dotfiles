// Main-screen workspaces: 1-4 always, plus any higher one that is active or has windows. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Pill {
    padding: 4
    readonly property var extra: Hyprland.workspaces.values
        .filter(w => w.id > 4 && w.monitor && w.monitor.name === "DP-1"
                     && ((w.toplevels && w.toplevels.values.length > 0) || (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === w.id)))
        .map(w => w.id)
    readonly property var ids: [1, 2, 3, 4].concat(extra.filter((v, i, a) => a.indexOf(v) === i).sort((a, b) => a - b))

    Repeater {
        model: ids
        Rectangle {
            required property var modelData
            readonly property int wsId: modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            readonly property bool isActive: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)
                                             || !!(ws && ws.monitor && ws.monitor.name === "DP-1" && ws.monitor.activeWorkspace === ws)
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
