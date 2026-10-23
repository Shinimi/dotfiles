// Settings: label + a row of choice pills. options: [[value, text], ...]. Made by Claude.
import QtQuick
import QtQuick.Layouts

Column {
    id: r
    property string label; property string desc: ""; property var options: []; property var current; property color accent: Theme.blue
    signal picked(var value)
    width: parent ? parent.width : 300; spacing: 10
    Column {
        spacing: 2
        Label { text: r.label; color: "#e6e6e6"; font.pixelSize: 12 }
        Label { visible: r.desc !== ""; text: r.desc; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
    }
    Flow {
        width: parent.width; spacing: 6
        Repeater {
            model: r.options
            Rectangle {
                required property var modelData
                readonly property bool cur: r.current === modelData[0]
                width: t.implicitWidth + 28; height: 32; radius: 16
                color: cur ? "#ececec" : (m.containsMouse ? "#262626" : "#1c1c1c")
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { id: t; anchors.centerIn: parent; text: modelData[1]; color: cur ? "#0b0b0b" : "#b8b8b8"; font.pixelSize: 11; font.bold: cur }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.picked(modelData[0]) }
            }
        }
    }
}
