// Rounded container used for every bar section. Made by Claude.
import QtQuick

Rectangle {
    id: pill
    property alias content: row.data
    property bool hovered: mouse.containsMouse
    property bool active: false
    signal clicked(var mouse)
    signal scrolled(int delta)
    default property alias items: row.data
    property int padding: 11

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    // pills sit on the translucent bar: no box of their own, only a soft highlight
    color: active ? "#2effffff" : (hovered ? "#17ffffff" : "transparent")
    border.width: 0
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.scrolled(w.angleDelta.y)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
