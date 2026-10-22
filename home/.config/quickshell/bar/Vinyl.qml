// A record player for the desktop: the album art spins on a vinyl while music plays,
// and the tonearm lifts off when you pause. Made by Claude.
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

Item {
    id: v
    property string art: ""
    property bool playing: false
    property int size: 190
    width: size + size * 0.28; height: size

    Item {
        id: disc
        width: v.size; height: v.size
        // spins at roughly 33⅓ rpm; pausing freezes it in place instead of snapping back
        NumberAnimation on rotation { from: 0; to: 360; duration: 1800; loops: Animation.Infinite; running: true; paused: !v.playing }
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#0b0b0b"; border.width: 1; border.color: "#22ffffff" }
        Repeater {   // grooves
            model: 7
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: v.size * (0.92 - index * 0.065); height: width; radius: width / 2
                color: "transparent"; border.width: 1; border.color: index % 2 ? "#0dffffff" : "#16ffffff"
            }
        }
        ClippingRectangle {   // the label is the album art
            anchors.centerIn: parent
            width: v.size * 0.38; height: width; radius: width / 2; color: "#1a1a1a"
            Image { anchors.fill: parent; source: v.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: v.art !== ""
                    sourceSize.width: 160; sourceSize.height: 160 }
        }
        Rectangle { anchors.centerIn: parent; width: 7; height: 7; radius: 4; color: "#050505"; border.width: 1; border.color: "#33ffffff" }
    }
    // a light sheen that stays still while the record turns underneath (sells the spin)
    Shape {
        anchors.fill: disc; opacity: 0.55
        ShapePath {
            strokeWidth: -1
            fillGradient: ConicalGradient {
                centerX: v.size / 2; centerY: v.size / 2; angle: 35
                GradientStop { position: 0.00; color: "transparent" }
                GradientStop { position: 0.06; color: "#24ffffff" }
                GradientStop { position: 0.13; color: "transparent" }
                GradientStop { position: 0.50; color: "transparent" }
                GradientStop { position: 0.56; color: "#1cffffff" }
                GradientStop { position: 0.63; color: "transparent" }
            }
            PathAngleArc { centerX: v.size / 2; centerY: v.size / 2; radiusX: v.size / 2 - 1; radiusY: v.size / 2 - 1; startAngle: 0; sweepAngle: 360 }
        }
    }
    // tonearm: pivots at the top right, rests on the record while playing
    Item {
        x: v.size * 0.98; y: v.size * 0.06
        width: 1; height: 1
        rotation: v.playing ? 14 : -8
        Behavior on rotation { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        Rectangle { x: -9; y: -9; width: 18; height: 18; radius: 9; color: "#1c1c1c"; border.width: 1; border.color: "#44ffffff" }
        Rectangle { x: -2; y: 0; width: 4; height: v.size * 0.6; radius: 2; color: "#bdbdbd" }
        Rectangle { x: -6; y: v.size * 0.6; width: 12; height: 18; radius: 3; color: "#eaeaea" }
    }
}
