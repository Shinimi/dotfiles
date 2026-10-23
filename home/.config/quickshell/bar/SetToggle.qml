// Settings row with a switch. Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    id: r
    property string label; property string desc: ""; property string key
    readonly property bool on: !!Settings.get(key)
    width: parent ? parent.width : 300; height: 42
    RowLayout {
        anchors.fill: parent
        Column {
            Layout.fillWidth: true; Layout.rightMargin: 8; spacing: 1
            Label { width: parent.width; elide: Text.ElideRight; text: r.label; color: "#e6e6e6"; font.pixelSize: 12 }
            Label { width: parent.width; elide: Text.ElideRight; visible: r.desc !== ""; text: r.desc; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
        }
        SetSwitchBox { on: r.on }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set(r.key, !r.on) }
}
