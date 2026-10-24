// The switch used by settings rows: a white pill with a dark knob when on. Made by Claude.
import QtQuick

Rectangle {
    id: sw
    property bool on: false
    width: 40; height: 22; radius: 11
    color: on ? "#ececec" : "#262626"
    border.width: 1; border.color: on ? "#ececec" : "#303030"
    Behavior on color { ColorAnimation { duration: 160 } }
    Rectangle {
        width: 16; height: 16; radius: 8; y: 3
        x: sw.on ? sw.width - width - 3 : 3
        color: sw.on ? "#0b0b0b" : "#8a8a8a"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
