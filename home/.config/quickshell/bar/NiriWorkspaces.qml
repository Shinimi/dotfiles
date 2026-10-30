// The workspace dots, for Niri: same look as Workspaces.qml (a stretched white pill for the one you're on, grey dots
// for ones with windows, dark for empty, a pulsing one wants attention). Niri numbers workspaces per screen, so each
// screen's bar shows its own. Click or scroll to switch. Made by Claude.
import QtQuick

Item {
    id: p
    property string screenName: "DP-1"
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 22
    readonly property var mine: Niri.workspaces.filter(w => w.output === screenName).sort((a, b) => a.idx - b.idx)
    // always 4, plus any higher one that has windows or is open (Niri keeps one empty workspace at the end: hidden)
    readonly property int shown: Math.max(4, ...mine.filter(w => (Niri.count[w.id] || 0) > 0 || w.is_active).map(w => w.idx))
    function go(i) { Niri.onScreen(screenName, ["focus-workspace", String(i)]) }

    MouseArea {
        anchors.fill: parent
        onWheel: w => Niri.onScreen(p.screenName, [w.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down"])
    }
    Row {
        id: row
        anchors.centerIn: parent
        Repeater {
            model: p.shown
            Item {
                id: chip
                required property int index
                readonly property var ws: p.mine.find(w => w.idx === index + 1)
                readonly property bool isActive: !!(ws && ws.is_active)
                readonly property bool hasWindows: !!(ws && (Niri.count[ws.id] || 0) > 0)
                readonly property bool urgent: !!(ws && ws.is_urgent) && !isActive
                width: isActive ? 28 : 14; height: 22
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: chip.isActive ? 22 : 7; height: 7; radius: 4
                    color: chip.isActive ? "#f2f2f2" : m.containsMouse ? "#d0d0d0" : chip.urgent ? "#ffffff" : chip.hasWindows ? "#8a8a8a" : "#3a3a3a"
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    SequentialAnimation on opacity {
                        running: chip.urgent; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 } NumberAnimation { to: 1; duration: 500 }
                    }
                }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: p.go(chip.index + 1) }
            }
        }
    }
}
