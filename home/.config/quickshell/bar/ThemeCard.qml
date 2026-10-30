// Settings → Theme: one choice in an "everything installed" picker. Shows its own preview (children) above a name;
// the picked one gets a bright outline and a check, not a white fill, so white cursors and light icons stay visible.
// Made by Claude.
import QtQuick

Rectangle {
    id: c
    default property alias preview: box.data
    property string title: ""; property string sub: ""; property bool on: false
    property int previewHeight: 44
    signal picked()
    height: previewHeight + 52; radius: 14
    color: on ? "#191919" : m.containsMouse ? "#161616" : "#0f0f0f"
    border.width: on ? 1.5 : 1; border.color: on ? "#ececec" : m.containsMouse ? "#33ffffff" : "#222222"
    Behavior on color { ColorAnimation { duration: 130 } }
    scale: m.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    Item { id: box; x: 12; y: 12; width: parent.width - 24; height: c.previewHeight; clip: true }
    Column {
        x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: parent.width - 24 - (c.on ? 22 : 0); spacing: 1
        Text { width: parent.width; elide: Text.ElideRight; text: c.title; color: "#ececec"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
        Text { visible: c.sub !== ""; width: parent.width; elide: Text.ElideRight; text: c.sub; color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 9 }
    }
    Rectangle {   // check
        visible: c.on; width: 18; height: 18; radius: 9; color: "#ececec"
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        Text { anchors.centerIn: parent; text: "\u{f012c}"; color: "#0b0b0b"; font.family: Theme.font; font.pixelSize: 11 }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.picked() }
}
