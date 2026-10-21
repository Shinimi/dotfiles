// Main-screen workspaces: 1-4 always, plus any higher one that is active or has windows.
// Each shows tiny icons of the apps open on it. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

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
            readonly property var apps: {
                const out = []
                if (ws && ws.toplevels) for (const t of ws.toplevels.values) {
                    const c = t.lastIpcObject && t.lastIpcObject.class ? t.lastIpcObject.class : ""
                    if (c && out.indexOf(c) < 0) out.push(c)
                }
                return out.slice(0, 3)
            }
            width: Math.max(isActive ? 30 : 22, inner.implicitWidth + 14); height: 20; radius: 7
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            color: isActive ? Theme.blue : (wsMouse.containsMouse ? Theme.bgHover : "transparent")
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Row {
                id: inner
                anchors.centerIn: parent; spacing: 5
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: wsId
                    color: isActive ? Theme.bg : (hasWindows ? Theme.fg : Theme.muted)
                }
                Repeater {
                    model: apps
                    IconImage {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 13; opacity: isActive ? 1 : 0.7
                        source: {
                            const e = DesktopEntries.heuristicLookup(modelData)
                            return Quickshell.iconPath(e && e.icon ? e.icon : modelData.toLowerCase(), true) || ""
                        }
                    }
                }
            }
            MouseArea {
                id: wsMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"])
            }
        }
    }
}
