// Settings → Bluetooth: adapter on/off and devices (shows a hint when there's no adapter). Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Column {
    id: pg
    spacing: 14
    readonly property var adapter: Bluetooth.defaultAdapter
    Rectangle {
        visible: !pg.adapter
        width: parent.width; height: 170; radius: 22; color: "#131313"
        Column {
            anchors.centerIn: parent; spacing: 8
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f00b2}"; color: Theme.line; font.pixelSize: 40 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "No Bluetooth adapter found"; font.pixelSize: 15 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Your motherboard has none built in. Plug in a USB Bluetooth dongle and it shows up here."; color: Theme.muted; font.pixelSize: 11 }
        }
    }
    SetSection {
        visible: !!pg.adapter; width: parent.width; title: "Bluetooth"; icon: "\u{f00af}"
        SetSwitch { label: "Bluetooth"; desc: pg.adapter ? pg.adapter.name : ""; on: pg.adapter ? pg.adapter.enabled : false; onToggled: pg.adapter.enabled = !pg.adapter.enabled }
        SetSwitch { label: "Look for new devices"; visible: pg.adapter && pg.adapter.enabled; on: pg.adapter ? pg.adapter.discovering : false; onToggled: pg.adapter.discovering = !pg.adapter.discovering }
    }
    SetSection {
        visible: !!pg.adapter && pg.adapter.enabled; width: parent.width; title: "Devices"; icon: "\u{f00b1}"
        Repeater {
            model: pg.adapter ? pg.adapter.devices : []
            Rectangle {
                id: bd
                required property var modelData
                width: parent.width; height: 48; radius: 14; color: "#1a1a1a"
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    Label { text: bd.modelData.connected ? "\u{f00b1}" : "\u{f00af}"; color: bd.modelData.connected ? Theme.blue : Theme.muted; font.pixelSize: 16 }
                    Column {
                        Label { text: bd.modelData.name || bd.modelData.address; font.pixelSize: 12 }
                        Label { text: bd.modelData.connected ? "Connected" + (bd.modelData.batteryAvailable ? " · " + Math.round(bd.modelData.battery * 100) + "%" : "") : (bd.modelData.paired ? "Paired" : "New"); color: Theme.muted; font.pixelSize: 10 }
                    }
                }
                SetButton {
                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                    text: bd.modelData.connected ? "Disconnect" : (bd.modelData.paired ? "Connect" : "Pair")
                    onClicked: bd.modelData.connected ? bd.modelData.disconnect() : (bd.modelData.paired ? bd.modelData.connect() : bd.modelData.pair())
                }
            }
        }
        Label { visible: pg.adapter && pg.adapter.devices.values.length === 0; text: "No devices yet. Turn on \u201cLook for new devices\u201d and put yours in pairing mode."; color: Theme.muted; font.pixelSize: 11 }
    }
}
