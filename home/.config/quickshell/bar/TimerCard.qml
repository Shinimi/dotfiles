// Timer | Stopwatch card for the clock panel. Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    property int tab: Timers.swActive && !Timers.timerActive ? 1 : 0
    width: parent ? parent.width : 280
    height: col.implicitHeight + 24
    radius: 12; color: Theme.bgAlt

    component Btn: Rectangle {
        property string text; property bool primary: false; property bool on: false; signal hit()
        Layout.fillWidth: true; Layout.preferredWidth: 1
        height: 30; radius: 8
        color: primary ? (bMouse.containsMouse ? "#8fb0ff" : Theme.blue) : (on ? Theme.bgHover : (bMouse.containsMouse ? Theme.bgHover : Theme.bg))
        border.width: on ? 1 : 0; border.color: Theme.blue
        Label { anchors.centerIn: parent; text: parent.text; color: parent.primary ? Theme.bg : Theme.fg; font.pixelSize: 11 }
        MouseArea { id: bMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    Column {
        id: col
        x: 12; y: 12; width: parent.width - 24; spacing: 10
        RowLayout {   // tabs
            width: parent.width; spacing: 6
            Repeater {
                model: ["  Timer", "  Stopwatch"]
                Rectangle {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; height: 26; radius: 7
                    color: card.tab === index ? Theme.bgHover : "transparent"
                    Label { anchors.centerIn: parent; text: modelData; font.pixelSize: 11; color: card.tab === index ? Theme.fg : Theme.muted }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.tab = index }
                }
            }
        }
        // ---- timer
        Column {
            visible: card.tab === 0
            width: parent.width; spacing: 10
            RowLayout {
                width: parent.width
                Btn { text: "−1"; Layout.preferredWidth: 0.5; onHit: Timers.addMinutes(-1) }
                Label {
                    Layout.fillWidth: true; Layout.preferredWidth: 2; horizontalAlignment: Text.AlignHCenter
                    text: Timers.fmt(Timers.remaining); font.pixelSize: 30; font.weight: Font.Bold
                    color: Timers.timerRunning ? Theme.blue : Theme.fg
                }
                Btn { text: "+1"; Layout.preferredWidth: 0.5; onHit: Timers.addMinutes(1) }
            }
            Rectangle {
                width: parent.width; height: 4; radius: 2; color: Theme.bg
                Rectangle { width: parent.width * (Timers.total > 0 ? Timers.remaining / Timers.total : 0); height: 4; radius: 2; color: Theme.blue
                    Behavior on width { NumberAnimation { duration: 900 } } }
            }
            RowLayout {
                width: parent.width; spacing: 6
                Repeater {
                    model: [1, 5, 10, 25]
                    Btn { required property var modelData; text: modelData + "m"; on: !Timers.timerRunning && Timers.total === modelData * 60; onHit: Timers.setMinutes(modelData) }
                }
            }
            RowLayout {
                width: parent.width; spacing: 6
                Btn { text: Timers.timerRunning ? "  Pause" : "  Start"; primary: true; onHit: Timers.toggleTimer() }
                Btn { text: "  Reset"; onHit: Timers.resetTimer() }
            }
        }
        // ---- stopwatch
        Column {
            visible: card.tab === 1
            width: parent.width; spacing: 10
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Timers.fmtSw(Timers.elapsed); font.pixelSize: 30; font.weight: Font.Bold
                color: Timers.swRunning ? Theme.green : Theme.fg
            }
            RowLayout {
                width: parent.width; spacing: 6
                Btn { text: Timers.swRunning ? "  Pause" : "  Start"; primary: true; onHit: Timers.toggleStopwatch() }
                Btn { text: "  Reset"; onHit: Timers.resetStopwatch() }
            }
        }
    }
}
