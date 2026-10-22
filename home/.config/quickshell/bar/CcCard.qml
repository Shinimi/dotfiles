// Control center building block (Card): a light veil on the glass with an optional header. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    default property alias inner: cardCol.data
    property string title: ""
    property string icon: ""
    property string note: ""          // small text on the right of the header
    width: parent ? parent.width : 300
    height: cardCol.implicitHeight + 28
    radius: 2; color: Theme.card
    border.width: 1; border.color: Theme.stroke
    Column {
        id: cardCol
        x: 14; y: 14; width: parent.width - 28; spacing: 12
        RowLayout {
            visible: title !== ""
            width: parent.width; spacing: 8
            Label { text: icon; color: Theme.muted; font.pixelSize: 12 }
            Label { text: title.toUpperCase(); color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.2; Layout.fillWidth: true }
            Label { visible: note !== ""; text: note; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
        }
    }
}
