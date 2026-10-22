// Settings → Network: connection details, live speed, Wi-Fi if there is a card. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property var net: ({ devices: [], wifi: [], wifiOn: false })
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : b + " B/s" }
    Process {
        id: load; running: pg.visible
        command: ["python3", "-I", Qt.resolvedUrl("sysinfo.py").toString().replace("file://", ""), "network"]
        stdout: StdioCollector { onStreamFinished: { try { pg.net = JSON.parse(this.text) } catch (e) {} } }
    }
    Repeater {
        model: pg.net.devices
        Rectangle {
            id: dc
            required property var modelData
            readonly property bool up: modelData.state.indexOf("connected") === 0
            width: pg.width; height: 190; radius: 2; color: Theme.card; border.width: 1; border.color: up ? Qt.rgba(0.78, 0.78, 0.78, 0.4) : "#14eaeaea"
            Row {
                x: 22; y: 20; spacing: 16
                Rectangle {
                    width: 52; height: 52; radius: 2; color: dc.up ? Qt.rgba(0.78, 0.78, 0.78, 0.18) : Theme.bgAlt
                    Label { anchors.centerIn: parent; text: dc.modelData.type === "wifi" ? "\u{f05a9}" : "\u{f0200}"; color: dc.up ? Theme.green : Theme.muted; font.pixelSize: 24 }
                }
                Column {
                    spacing: 3
                    Label { text: dc.modelData.connection || dc.modelData.device; font.pixelSize: 17; font.weight: Font.Bold }
                    Label { text: (dc.up ? "Connected" : dc.modelData.state) + " · " + (dc.modelData.type === "ethernet" ? "Wired" : dc.modelData.type) + (dc.modelData.speed > 0 ? " · " + (dc.modelData.speed >= 1000 ? dc.modelData.speed / 1000 + " Gbit/s" : dc.modelData.speed + " Mbit/s") : ""); color: dc.up ? Theme.green : Theme.muted; font.pixelSize: 12 }
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 22; y: 26; spacing: 18
                Label { text: "\u{f0045} " + pg.speed(Stats.d.netRx || 0); color: Theme.green; font.pixelSize: 13 }
                Label { text: "\u{f005d} " + pg.speed(Stats.d.netTx || 0); color: Theme.purple; font.pixelSize: 13 }
            }
            GridLayout {
                x: 22; y: 96; width: parent.width - 44; columns: 4; columnSpacing: 10; rowSpacing: 4
                Repeater {
                    model: [["IP address", (dc.modelData["IP4.ADDRESS"] || "–").split("/")[0]], ["Router", dc.modelData["IP4.GATEWAY"] || "–"],
                            ["DNS", (dc.modelData["IP4.DNS"] || "–").split("#")[0]], ["Device", dc.modelData.device]]
                    Column {
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        Label { text: modelData[0]; color: Theme.muted; font.pixelSize: 10 }
                        Label { text: modelData[1]; font.pixelSize: 13 }
                    }
                }
            }
        }
    }
    SetSection {
        visible: pg.net.wifi.length > 0; width: parent.width; title: "Wi-Fi"; icon: "\u{f05a9}"
        Repeater {
            model: pg.net.wifi
            Row {
                required property var modelData
                spacing: 12
                Label { text: modelData.signal > 66 ? "\u{f0928}" : modelData.signal > 33 ? "\u{f0925}" : "\u{f091f}"; color: modelData.active ? Theme.green : Theme.fgDim }
                Label { text: modelData.ssid + (modelData.secure ? "  \u{f033e}" : "") + (modelData.active ? "  · connected" : ""); color: modelData.active ? Theme.green : Theme.fg; font.pixelSize: 12 }
            }
        }
    }
    Row {
        spacing: 8
        SetButton { icon: "\u{f0493}"; text: "Advanced network settings"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        SetButton { icon: "\u{f0450}"; text: "Refresh"; onClicked: load.running = true }
    }
}
