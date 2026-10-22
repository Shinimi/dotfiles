// Settings: a switch row that isn't stored in settings.json (state passed in). Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    id: r
    property string label; property string desc: ""; property bool on: false; property color accent: Theme.blue
    signal toggled()
    width: parent ? parent.width : 300; height: 40
    RowLayout {
        anchors.fill: parent
        Column {
            Layout.fillWidth: true; Layout.rightMargin: 8; spacing: 1
            Label { width: parent.width; elide: Text.ElideRight; text: r.label; color: "#e0e0e0"; font.pixelSize: 12 }
            Label { width: parent.width; elide: Text.ElideRight; visible: r.desc !== ""; text: r.desc; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
        }
        SetSwitchBox { on: r.on }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: r.toggled() }
}
