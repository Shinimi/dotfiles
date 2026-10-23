// Settings: a pill button (white when primary). Made by Claude.
import QtQuick

Rectangle {
    id: b
    property string icon: ""; property string text: ""; property color accent: Theme.blue; property bool primary: false
    signal clicked()
    implicitWidth: row.implicitWidth + 32; implicitHeight: 36; radius: 18
    readonly property bool lit: primary || m.containsMouse
    color: primary ? (m.containsMouse ? "#ffffff" : "#ececec") : (m.containsMouse ? "#ececec" : "#1c1c1c")
    Behavior on color { ColorAnimation { duration: 120 } }
    Row {
        id: row; anchors.centerIn: parent; spacing: 8
        Label { visible: b.icon !== ""; text: b.icon; color: b.lit ? "#0b0b0b" : "#cfcfcf"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        Label { text: b.text.charAt(0).toUpperCase() + b.text.slice(1).toLowerCase(); color: b.lit ? "#0b0b0b" : "#e6e6e6"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
