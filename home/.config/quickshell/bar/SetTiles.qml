// Settings: a choice shown as picture tiles (icon, name, a short line) instead of pills; white = picked.
// options: [[value, title, sub, icon], ...]. Made by Claude.
import QtQuick

Item {
    id: r
    property string label: ""; property string desc: ""
    property var options: []; property var current
    property int columns: Math.min(4, options.length)
    signal picked(var value)
    width: parent ? parent.width : 300; implicitHeight: inner.implicitHeight
    SetRowLine { show: r.Positioner.index > 0 }
    Column {
        id: inner
        width: parent.width; spacing: 10
        Column {
            visible: r.label !== ""; spacing: 2; width: parent.width
            Label { text: r.label; color: "#e6e6e6"; font.pixelSize: 12 }
            Label { visible: r.desc !== ""; width: parent.width; wrapMode: Text.WordWrap; text: r.desc.charAt(0).toUpperCase() + r.desc.slice(1); color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal }
        }
        Grid {
            width: parent.width; columns: r.columns; columnSpacing: 8; rowSpacing: 8
            Repeater {
                model: r.options
                Rectangle {
                    id: t
                    required property var modelData
                    readonly property bool on: JSON.stringify(r.current) === JSON.stringify(modelData[0])
                    readonly property bool hasIcon: (modelData[3] || "") !== ""
                    width: (parent.width - 8 * (r.columns - 1)) / r.columns
                    height: (hasIcon ? 34 : 14) + (modelData[2] ? 38 : 24)
                    radius: 14; color: on ? "#ececec" : tm.containsMouse ? "#1c1c1c" : "#0f0f0f"
                    border.width: 1; border.color: on ? "#ececec" : tm.containsMouse ? "#33ffffff" : "#222222"
                    Behavior on color { ColorAnimation { duration: 130 } }
                    scale: tm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    Text { visible: t.hasIcon; x: 12; y: 12; text: t.modelData[3] || ""; color: t.on ? "#0b0b0b" : "#cfcfcf"; font.family: Theme.font; font.pixelSize: 17 }
                    Column {
                        x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: parent.width - 24; spacing: 1
                        Text { width: parent.width; elide: Text.ElideRight; text: t.modelData[1]; color: t.on ? "#0b0b0b" : "#ececec"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                        Text { visible: !!t.modelData[2]; width: parent.width; elide: Text.ElideRight; text: t.modelData[2] || ""; color: t.on ? "#70000000" : "#6e6e6e"; font.family: Theme.font; font.pixelSize: 9 }
                    }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.picked(t.modelData[0]) }
                }
            }
        }
    }
}
