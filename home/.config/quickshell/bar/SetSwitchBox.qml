// The square switch used by settings rows: white when on. Made by Claude.
import QtQuick

Rectangle {
    id: sw
    property bool on: false
    width: 40; height: 20; radius: 2
    color: on ? Theme.on : "transparent"
    border.width: 1; border.color: on ? Theme.on : "#55ffffff"
    Behavior on color { ColorAnimation { duration: 140 } }
    Rectangle {
        width: 12; height: 12; radius: 1; y: 4
        x: sw.on ? sw.width - width - 4 : 4
        color: sw.on ? Theme.onText : "#9a9a9a"
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
}
