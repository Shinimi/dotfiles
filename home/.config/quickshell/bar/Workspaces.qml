// Main-screen workspaces: 1-4 always, plus any higher one that is active or has windows.
// Active = white pill; a small dot marks workspaces that have windows. Made by Claude.
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
            width: Math.max(isActive ? 38 : 26, wsLabel.implicitWidth + 14); height: 24; radius: 12
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            color: isActive ? Theme.on : (wsMouse.containsMouse ? "#17ffffff" : "transparent")
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Label {
                id: wsLabel
                anchors.centerIn: parent
                text: Theme.wsName(wsId); font.pixelSize: Settings.cur("ws_kanji") ? 13 : 11; font.family: Settings.cur("ws_kanji") ? "Noto Sans CJK JP" : Theme.font
                color: isActive ? Theme.onText : (hasWindows ? Theme.fg : "#555555")
            }
            Rectangle {   // tiny dot: this workspace has windows
                visible: hasWindows && !isActive && !Settings.cur("ws_kanji")
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                width: 3; height: 3; radius: 2; color: Theme.fgDim
            }
            MouseArea {
                id: wsMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"])
            }
        }
    }
}
