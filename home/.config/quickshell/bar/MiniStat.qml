// Control center building block (MiniStat). Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    property string icon; property string title; property int usage; property int temp: -1; property string extra; property color accent
    Layout.fillWidth: true; Layout.preferredWidth: 1
    height: 86; radius: 12; color: "#6613121c"
    Column {
        x: 10; y: 10; width: parent.width - 20; spacing: 6
        RowLayout { width: parent.width
            Label { text: icon + "  " + title; color: accent; font.pixelSize: 11; Layout.fillWidth: true }
            Label { visible: temp >= 0; text: temp + "°"; color: temp >= 85 ? Theme.red : temp >= 70 ? Theme.yellow : Theme.green; font.pixelSize: 11 } }
        Label { text: usage + "%"; font.pixelSize: 20; font.weight: Font.Bold }
        Rectangle { width: parent.width; height: 4; radius: 2; color: "#33efeaf8"
            Rectangle { width: Math.max(4, parent.width * Math.min(1, usage / 100)); height: 4; radius: 2; color: accent
                Behavior on width { NumberAnimation { duration: 300 } } } }
        Label { text: extra; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Normal }
    }
}
