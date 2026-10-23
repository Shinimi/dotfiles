// A settings card: a soft dark block with a small title and icon. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sec
    default property alias inner: col.data
    property string title; property string icon
    readonly property bool isSection: true
    implicitWidth: 300               // the RowLayout decides the real width
    implicitHeight: col.implicitHeight + 40
    radius: 22; color: "#131313"
    Column {
        id: col
        x: 20; y: 18; width: parent.width - 40; spacing: 14
        RowLayout {
            width: parent.width; spacing: 10
            Text { text: sec.icon; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 14 }
            Text { text: sec.title; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
        }
    }
}
