// One stat row: icon, label, value and a progress bar. Made by Claude.
import QtQuick
import QtQuick.Layouts

Column {
    property string icon; property string label; property string value
    property real fraction: 0; property color accent: Theme.blue
    width: parent ? parent.width : 0; spacing: 6
    RowLayout {
        width: parent.width
        Label { text: icon; color: accent; Layout.preferredWidth: 22 }
        Label { text: label; color: Theme.fgDim; Layout.fillWidth: true }
        Label { text: value }
    }
    Rectangle {
        width: parent.width; height: 6; radius: 3; color: Theme.bgAlt
        Rectangle {
            width: Math.max(height, parent.width * Math.min(1, Math.max(0, fraction))); height: parent.height; radius: 3; color: accent
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
}
