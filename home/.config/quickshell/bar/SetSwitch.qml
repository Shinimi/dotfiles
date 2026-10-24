// Settings: a switch row that isn't stored in settings.json (state passed in). Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    id: r
    property string label; property string desc: ""; property bool on: false; property color accent: Theme.blue
    signal toggled()
    width: parent ? parent.width : 300; height: Math.max(30, txt.implicitHeight + 4)
    SetRowLine { show: r.Positioner.index > 0 }
    RowLayout {
        anchors.fill: parent
        Column {
            id: txt
            Layout.fillWidth: true; Layout.rightMargin: 8; spacing: 2
            Label { width: parent.width; elide: Text.ElideRight; text: r.label; color: "#e6e6e6"; font.pixelSize: 12 }
            Label { width: parent.width; wrapMode: Text.WordWrap; visible: r.desc !== ""; text: r.desc.charAt(0).toUpperCase() + r.desc.slice(1); color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
        }
        SetSwitchBox { on: r.on }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: r.toggled() }
}
