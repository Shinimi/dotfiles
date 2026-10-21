// CPU / GPU card: big usage %, bar, temperature + one extra stat. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    property string icon; property string title
    property int usage; property int temp; property string extra; property string extraIcon
    property color accent: Theme.cyan
    readonly property color tempColor: temp >= 85 ? Theme.red : temp >= 70 ? Theme.yellow : Theme.green
    implicitHeight: col.implicitHeight + 24
    radius: 12; color: Theme.bgAlt
    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 12; spacing: 8
        RowLayout {
            width: parent.width
            Label { text: icon; color: accent }
            Label { text: title; color: Theme.fgDim; Layout.fillWidth: true }
        }
        Label { text: usage + "%"; font.pixelSize: 26; font.weight: Font.Bold; color: Theme.fg }
        Rectangle {
            width: parent.width; height: 6; radius: 3; color: Theme.bg
            Rectangle {
                width: Math.max(height, parent.width * Math.min(1, usage / 100)); height: parent.height; radius: 3; color: accent
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
        RowLayout {
            width: parent.width
            Label { text: " " + temp + "°C"; color: tempColor; font.pixelSize: 11; Layout.fillWidth: true }
            Label { text: extraIcon + " " + extra; color: Theme.muted; font.pixelSize: 11 }
        }
    }
}
