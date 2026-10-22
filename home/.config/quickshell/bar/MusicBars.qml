// Three little bouncing bars while music plays (stops animating when hidden). Made by Claude.
import QtQuick

Row {
    id: bars
    property bool running: false
    spacing: 2
    height: 12
    Repeater {
        model: [[0.35, 520], [0.9, 410], [0.55, 610]]
        Rectangle {
            required property var modelData
            anchors.bottom: parent.bottom
            width: 3; radius: 1.5; color: Theme.fg
            height: bars.height * (bars.running ? lvl : 0.3)
            property real lvl: modelData[0]
            SequentialAnimation on lvl {
                running: bars.running; loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: modelData[1]; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.25; duration: modelData[1] * 0.8; easing.type: Easing.InOutSine }
                NumberAnimation { to: modelData[0]; duration: modelData[1] * 0.6; easing.type: Easing.InOutSine }
            }
        }
    }
}
