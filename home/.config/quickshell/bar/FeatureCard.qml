// Settings: one feature as a card: icon, name, a two-line description and its switch (or an Open button for things
// you start rather than turn on). key = a setting; or set on/onToggled yourself; action = true for an Open button.
// Made by Claude.
import QtQuick

Rectangle {
    id: c
    property string icon; property string label; property string desc: ""; property string key: ""
    property bool on: key !== "" ? !!Settings.get(key) : false
    property bool action: false
    property string hint: ""          // a shortcut shown as a small chip
    signal toggled()
    height: 112; radius: 16
    color: cm.containsMouse ? "#181818" : "#131313"; border.width: 1; border.color: c.on && !c.action ? "#3a3a3a" : "#1d1d1d"
    Behavior on color { ColorAnimation { duration: 120 } }
    Rectangle {
        x: 14; y: 14; width: 34; height: 34; radius: 11; color: c.on && !c.action ? "#ececec" : "#1f1f1f"
        Behavior on color { ColorAnimation { duration: 160 } }
        Text { anchors.centerIn: parent; text: c.icon; color: c.on && !c.action ? "#0b0b0b" : "#d0d0d0"; font.family: Theme.font; font.pixelSize: 16 }
    }
    SetSwitchBox { visible: !c.action; on: c.on; anchors.right: parent.right; anchors.rightMargin: 14; y: 20 }
    Rectangle {
        visible: c.action; anchors.right: parent.right; anchors.rightMargin: 14; y: 18
        width: ot.implicitWidth + 20; height: 26; radius: 13; color: cm.containsMouse ? "#ececec" : "#1f1f1f"
        Text { id: ot; anchors.centerIn: parent; text: "Open"; color: cm.containsMouse ? "#0b0b0b" : "#d0d0d0"; font.family: Theme.font; font.pixelSize: 10; font.bold: true }
    }
    Column {
        x: 14; y: 58; width: parent.width - 28; spacing: 3
        Row {
            spacing: 8; width: parent.width
            Text { text: c.label; color: "#ececec"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            Rectangle { visible: c.hint !== ""; width: ht.implicitWidth + 10; height: 16; radius: 5; color: "#1f1f1f"; anchors.verticalCenter: parent.verticalCenter
                        Text { id: ht; anchors.centerIn: parent; text: c.hint; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 9 } }
        }
        Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
               text: c.desc.charAt(0).toUpperCase() + c.desc.slice(1); color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 10 }
    }
    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (c.key !== "" && !c.action) Settings.set(c.key, !c.on); else c.toggled() } }
}
