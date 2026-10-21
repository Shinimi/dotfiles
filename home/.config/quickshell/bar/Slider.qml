// Minimal slider (0..1). Made by Claude.
import QtQuick

Item {
    id: s
    property real value: 0
    property color accent: Theme.blue
    signal moved(real v)
    implicitHeight: 18
    width: parent ? parent.width : 100
    Rectangle {
        id: track; anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 8; radius: 4; color: Theme.bgAlt
        Rectangle { width: Math.max(height, parent.width * s.value); height: parent.height; radius: 4; color: s.accent }
    }
    Rectangle {
        x: Math.max(0, Math.min(s.width - width, s.width * s.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 16; height: 16; radius: 8; color: Theme.fg
        border.width: 3; border.color: s.accent
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        function set(mx) { s.moved(Math.max(0, Math.min(1, mx / s.width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
    }
}
