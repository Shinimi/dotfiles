// A settings group: a small spaced-capitals title, then a soft box whose rows are split by thin lines. Made by Claude.
import QtQuick

Column {
    id: sec
    default property alias inner: col.data
    property string title; property string icon
    readonly property bool isSection: true
    spacing: 8
    Row {
        visible: sec.title !== ""
        x: 6; spacing: 8
        Text { text: sec.icon; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Text { text: sec.title.toUpperCase(); color: "#808080"; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; anchors.verticalCenter: parent.verticalCenter }
    }
    Rectangle {
        width: parent.width; height: col.implicitHeight + 32; radius: 18
        color: "#111111"; border.width: 1; border.color: "#1c1c1c"
        Column { id: col; x: 18; y: 16; width: parent.width - 36; spacing: 12 }
    }
}
