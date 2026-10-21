// Control center building block (Tile). Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    property string icon; property string title; property string sub; property bool on: false; property color accent: Theme.blue
    signal hit()
    Layout.fillWidth: true; Layout.preferredWidth: 1
    height: 58; radius: 14
    color: on ? accent : (tMouse.containsMouse ? "#33efeaf8" : Theme.card)
    border.width: 1; border.color: on ? accent : "#14efeaf8"
    Behavior on color { ColorAnimation { duration: 140 } }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 10
        Rectangle {
            width: 32; height: 32; radius: 16
            color: on ? Qt.rgba(0, 0, 0, 0.18) : "#6613121c"
            Label { anchors.centerIn: parent; text: icon; color: on ? Theme.bg : accent; font.pixelSize: 13 }
        }
        Column {
            Layout.fillWidth: true; spacing: 1
            Label { text: title; color: on ? Theme.bg : Theme.fg; font.pixelSize: 12 }
            Label { text: sub; color: on ? Qt.rgba(0.07, 0.07, 0.11, 0.8) : Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
        }
    }
    MouseArea { id: tMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
}
