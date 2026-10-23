// Privacy indicator: shows up on the bar only while something is using the mic, the camera or sharing the
// screen. Click it to see which apps. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell

Pill {
    id: pill
    visible: Streams.anyLive
    active: pop.visible
    implicitWidth: row.implicitWidth + 20
    Row {
        id: row; spacing: 7
        Rectangle {   // a soft breathing dot, like a recording light
            anchors.verticalCenter: parent.verticalCenter
            width: 7; height: 7; radius: 4; color: "#ffffff"
            SequentialAnimation on opacity { running: pill.visible; loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900 } NumberAnimation { to: 1; duration: 900 } }
        }
        Label { visible: Streams.micLive; text: "\u{f036c}"; color: "#ffffff"; font.pixelSize: 13 }
        Label { visible: Streams.screenShared; text: "\u{f0379}"; color: "#ffffff"; font.pixelSize: 13 }
        Label { visible: Streams.videoUsers.length > 0 && !Streams.screenShared; text: "\u{f0567}"; color: "#ffffff"; font.pixelSize: 13 }
    }
    onClicked: pop.toggle()

    BarPopup {
        id: pop
        anchorItem: pill
        contentWidth: 260
        padding: 18
        Text { text: "in use right now"; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 11 }
        Repeater {
            model: [
                ["\u{f036c}", "Microphone", Streams.micUsers],
                ["\u{f0379}", "Screen share", Streams.screenShared ? (Streams.videoUsers.length ? Streams.videoUsers : ["an app"]) : []],
                ["\u{f0567}", "Camera", !Streams.screenShared ? Streams.videoUsers : []]
            ]
            RowLayout {
                required property var modelData
                visible: modelData[2].length > 0
                width: parent.width; spacing: 12
                Rectangle {
                    width: 34; height: 34; radius: 17; color: "#ececec"
                    Text { anchors.centerIn: parent; text: modelData[0]; color: "#0b0b0b"; font.family: Theme.font; font.pixelSize: 15 }
                }
                Column {
                    Layout.fillWidth: true; spacing: 2
                    Text { text: modelData[1]; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[2].join(", "); color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11 }
                }
            }
        }
    }
}
