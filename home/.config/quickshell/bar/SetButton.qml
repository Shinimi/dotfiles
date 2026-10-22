// Settings: a pill button. Made by Claude.
import QtQuick

Rectangle {
    id: b
    property string icon: ""; property string text: ""; property color accent: Theme.blue; property bool primary: false
    signal clicked()
    implicitWidth: row.implicitWidth + 28; implicitHeight: 32; radius: 2
    color: primary ? (m.containsMouse ? "#ffffff" : Theme.on) : (m.containsMouse ? "#14ffffff" : "transparent")
    border.width: 1; border.color: primary ? Theme.on : "#33ffffff"
    Behavior on color { ColorAnimation { duration: 120 } }
    Row {
        id: row; anchors.centerIn: parent; spacing: 8
        Label { visible: b.icon !== ""; text: b.icon; color: b.primary ? Theme.onText : b.accent; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        Label { text: b.text.toUpperCase(); color: b.primary ? Theme.onText : Theme.fg; font.pixelSize: 10; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
