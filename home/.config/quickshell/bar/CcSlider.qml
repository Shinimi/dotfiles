// Big pill slider for the control center: the fill carries the icon, click the icon to mute.
// Made by Claude.
import QtQuick

Item {
    id: s
    property real value: 0
    property string icon: ""
    property string text: ""          // label shown inside, left
    property bool muted: false
    signal moved(real v)
    signal iconClicked()
    height: 36
    width: parent ? parent.width : 200
    readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.fill: parent; radius: 2
        color: ma.containsMouse ? "#16ffffff" : "#0fffffff"
        border.width: 1; border.color: Theme.stroke
        clip: true
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {   // fill
            height: parent.height; radius: 2
            width: Math.max(height, parent.width * s.shown)
            color: s.muted ? "#33ffffff" : Theme.on
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
    // icon sits on the fill's left cap (dark on white)
    Item {
        id: ic
        width: s.height; height: s.height
        Label { anchors.centerIn: parent; text: s.icon; font.pixelSize: 15; color: s.muted ? Theme.muted : Theme.onText }
    }
    Label {
        x: s.height + 2; anchors.verticalCenter: parent.verticalCenter
        text: s.text; font.pixelSize: 11
        // readable on both the white fill and the dark track
        color: s.shown * s.width > x + implicitWidth ? Theme.onText : Theme.fgDim
    }
    Label {
        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
        text: s.muted ? "muted" : Math.round(s.value * 100) + "%"; font.pixelSize: 11
        color: s.shown > 0.93 ? Theme.onText : Theme.muted
    }
    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; preventStealing: true
        property bool onIcon: false
        function set(mx) { s.moved(Math.max(0, Math.min(1, mx / s.width))) }
        onPressed: m => { onIcon = m.x < s.height; if (!onIcon) set(m.x) }
        onPositionChanged: m => { if (pressed && !onIcon) set(m.x) }
        onClicked: m => { if (onIcon) s.iconClicked() }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
    }
}
