// Control center building block (MiniStat): a usage ring with the number inside. Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    property string icon; property string title; property int usage; property int temp: -1; property string extra; property color accent: Theme.on
    Layout.fillWidth: true; Layout.preferredWidth: 1
    height: 118
    Canvas {
        id: ring
        width: 74; height: 74; anchors.horizontalCenter: parent.horizontalCenter
        property real v: Math.min(1, Math.max(0, usage / 100))
        Behavior on v { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        onVChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            const r = width / 2 - 4, a0 = -Math.PI / 2
            c.lineWidth = 5; c.lineCap = "round"
            c.strokeStyle = "rgba(255,255,255,0.08)"; c.beginPath(); c.arc(width / 2, height / 2, r, 0, 2 * Math.PI); c.stroke()
            c.strokeStyle = temp >= 85 ? "#cf6b6b" : "#ededed"
            if (v > 0.005) { c.beginPath(); c.arc(width / 2, height / 2, r, a0, a0 + v * 2 * Math.PI); c.stroke() }
        }
        Column {
            anchors.centerIn: parent; spacing: -1
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: usage + "%"; font.pixelSize: 16; font.weight: Font.Bold }
            Label { anchors.horizontalCenter: parent.horizontalCenter; visible: temp >= 0; text: temp + "°"
                    color: temp >= 85 ? Theme.red : Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
        }
    }
    Column {
        anchors.top: ring.bottom; anchors.topMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; spacing: 1
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: title; font.pixelSize: 11 }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: extra; color: Theme.muted; font.pixelSize: 9; font.weight: Font.Normal }
    }
}
