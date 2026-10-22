// White corner brackets around the parent (the hub-style frame mark). Drop `Brackets {}` inside any box.
// Made by Claude.
import QtQuick

Item {
    id: br
    property int size: 11
    property int out: 4                    // how far they sit outside the box
    property color color: "#ffffff"
    anchors.fill: parent
    z: 50
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]
        Item {
            required property var modelData
            x: modelData[0] ? br.width - br.size + br.out : -br.out
            y: modelData[1] ? br.height - br.size + br.out : -br.out
            width: br.size; height: br.size
            Rectangle { x: modelData[0] ? br.size - 1 : 0; width: 1; height: br.size; color: br.color }
            Rectangle { y: modelData[1] ? br.size - 1 : 0; width: br.size; height: 1; color: br.color }
        }
    }
}
