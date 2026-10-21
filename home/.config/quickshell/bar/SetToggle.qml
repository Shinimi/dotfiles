// Settings row with a switch. Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    id: r
    property string label; property string desc: ""; property string key
    readonly property bool on: !!Settings.get(key)
    width: parent ? parent.width : 300; height: 40
    RowLayout {
        anchors.fill: parent
        Column {
            Layout.fillWidth: true; Layout.rightMargin: 8; spacing: 1
            Label { width: parent.width; elide: Text.ElideRight; text: r.label; color: Theme.fgDim; font.pixelSize: 12 }
            Label { width: parent.width; elide: Text.ElideRight; visible: r.desc !== ""; text: r.desc; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
        }
        Rectangle {
            width: 42; height: 24; radius: 12
            color: r.on ? Theme.blue : "#4dece4f6"
            Behavior on color { ColorAnimation { duration: 140 } }
            Rectangle {
                width: 18; height: 18; radius: 9; color: Theme.fg; y: 3
                x: r.on ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set(r.key, !r.on) }
}
