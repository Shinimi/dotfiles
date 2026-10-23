// The switch used by settings rows: a white pill with a dark knob when on. Made by Claude.
import QtQuick

Rectangle {
    id: sw
    property bool on: false
    width: 42; height: 24; radius: 12
    color: on ? "#ececec" : "#2a2a2a"
    Behavior on color { ColorAnimation { duration: 160 } }
    Rectangle {
        width: 18; height: 18; radius: 9; y: 3
        x: sw.on ? sw.width - width - 3 : 3
        color: sw.on ? "#0b0b0b" : "#8a8a8a"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
