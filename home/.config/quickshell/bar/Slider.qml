// Minimal slider (0..1): rounded track, white fill, a knob that grows on hover. Made by Claude.
import QtQuick

Item {
    id: s
    property real value: 0
    property color accent: "#ececec"
    signal moved(real v)
    implicitHeight: 20
    width: parent ? parent.width : 100
    readonly property bool hot: ma.containsMouse || ma.pressed
    Rectangle {
        id: track; anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6; radius: 3; color: "#2a2a2a"
        Rectangle { width: Math.max(height, parent.width * s.value); height: parent.height; radius: 3; color: s.accent }
    }
    Rectangle {
        readonly property int d: s.hot ? 18 : 14
        x: Math.max(0, Math.min(s.width - width, s.width * s.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: d; height: d; radius: d / 2; color: "#ffffff"
        border.width: 3; border.color: "#131313"
        Behavior on width { NumberAnimation { duration: 110 } }
        Behavior on height { NumberAnimation { duration: 110 } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent; anchors.topMargin: -6; anchors.bottomMargin: -6; cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        preventStealing: true   // don't let a scrolling page grab the drag
        function set(mx) { s.moved(Math.max(0, Math.min(1, mx / s.width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
    }
}
