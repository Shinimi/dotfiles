// Settings: a pill button. Made by Claude.
import QtQuick

Rectangle {
    id: b
    property string icon: ""; property string text: ""; property color accent: Theme.blue; property bool primary: false
    signal clicked()
    implicitWidth: row.implicitWidth + 28; implicitHeight: 34; radius: 11
    color: primary ? (m.containsMouse ? Qt.lighter(accent, 1.12) : accent) : (m.containsMouse ? Theme.bgHover : Theme.bgAlt)
    border.width: primary ? 0 : 1; border.color: "#1eece4f6"
    Behavior on color { ColorAnimation { duration: 120 } }
    Row {
        id: row; anchors.centerIn: parent; spacing: 8
        Label { visible: b.icon !== ""; text: b.icon; color: b.primary ? Theme.bg : b.accent; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        Label { text: b.text; color: b.primary ? Theme.bg : Theme.fg; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
