// Settings: label + a row of choice chips. options: [[value, text], ...]. Made by Claude.
import QtQuick
import QtQuick.Layouts

Column {
    id: r
    property string label; property string desc: ""; property var options: []; property var current; property color accent: Theme.blue
    signal picked(var value)
    width: parent ? parent.width : 300; spacing: 8
    Column {
        spacing: 1
        Label { text: r.label; color: Theme.fgDim; font.pixelSize: 12 }
        Label { visible: r.desc !== ""; text: r.desc; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
    }
    Flow {
        width: parent.width; spacing: 6
        Repeater {
            model: r.options
            Rectangle {
                required property var modelData
                readonly property bool cur: r.current === modelData[0]
                width: t.implicitWidth + 24; height: 30; radius: 10
                color: cur ? r.accent : (m.containsMouse ? Theme.bgHover : Theme.bgAlt)
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { id: t; anchors.centerIn: parent; text: modelData[1]; color: cur ? Theme.bg : Theme.fgDim; font.pixelSize: 11 }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.picked(modelData[0]) }
            }
        }
    }
}
