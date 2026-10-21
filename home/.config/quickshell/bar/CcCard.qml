// Control center building block (Card). Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    default property alias inner: cardCol.data
    property string title: ""
    property string icon: ""
    width: parent ? parent.width : 300
    height: cardCol.implicitHeight + 24
    radius: 14; color: Theme.card
    border.width: 1; border.color: "#14ece4f6"
    Column {
        id: cardCol
        x: 12; y: 12; width: parent.width - 24; spacing: 10
        RowLayout {
            visible: title !== ""
            width: parent.width
            Label { text: icon; color: Theme.blue; font.pixelSize: 12 }
            Label { text: title; color: Theme.fgDim; font.pixelSize: 11; Layout.fillWidth: true }
        }
    }
}
