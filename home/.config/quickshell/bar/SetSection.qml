// A settings card in the hub style: sharp corners, corner brackets and a numbered header (01 // TITLE).
// The number counts the cards on the page automatically. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sec
    default property alias inner: col.data
    property string title; property string icon
    readonly property bool isSection: true
    property int num: 1
    Component.onCompleted: {   // my position among the cards on this page
        let n = 0
        const walk = it => { for (const c of it.children) { if (c === sec) return true; if (c.isSection) n++; if (!c.isSection && walk(c)) return true } return false }
        let top = sec; while (top.parent && !top.parent.isPage) top = top.parent   // the page I'm on
        if (top) walk(top)
        num = n + 1
    }
    implicitWidth: 300               // the RowLayout decides the real width
    implicitHeight: col.implicitHeight + 30
    radius: 2; color: Theme.card; border.width: 1; border.color: "#26ffffff"
    Column {
        id: col
        x: 16; y: 14; width: parent.width - 32; spacing: 12
        RowLayout {
            width: parent.width; spacing: 8
            Text { text: String(sec.num).padStart(2, "0"); color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
            Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 10 }
            Text { text: sec.title.toUpperCase(); color: "#ececec"; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: sec.icon; color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 13 }
        }
        Rectangle { width: parent.width; height: 1; color: "#1affffff" }
    }
}
