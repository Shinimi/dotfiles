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
        Label { text: r.label; color: "#e0e0e0"; font.pixelSize: 12 }
        Label { visible: r.desc !== ""; text: r.desc; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
    }
    Flow {
        width: parent.width; spacing: 6
        Repeater {
            model: r.options
            Rectangle {
                required property var modelData
                readonly property bool cur: r.current === modelData[0]
                width: t.implicitWidth + 24; height: 28; radius: 2
                color: cur ? Theme.on : (m.containsMouse ? "#14ffffff" : "transparent")
                border.width: 1; border.color: cur ? Theme.on : "#33ffffff"
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { id: t; anchors.centerIn: parent; text: modelData[1]; color: cur ? Theme.onText : "#b0b0b0"; font.pixelSize: 11 }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.picked(modelData[0]) }
            }
        }
    }
}
