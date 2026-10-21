// A titled glass card for the settings panel. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    default property alias inner: col.data
    property string title; property string icon
    implicitWidth: 300               // the RowLayout decides the real width
    implicitHeight: col.implicitHeight + 28
    radius: 14; color: Theme.card; border.width: 1; border.color: "#14c0caf5"
    Column {
        id: col
        x: 14; y: 14; width: parent.width - 28; spacing: 12
        RowLayout {
            width: parent.width
            Label { text: icon; color: Theme.blue }
            Label { text: title; font.pixelSize: 13; font.weight: Font.Bold; Layout.fillWidth: true }
        }
    }
}
