// Settings → Storage: drives, health, space. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property var st: ({ mounts: [], drives: [] })
    function gb(b) { return b >= 1e12 ? (b / 1e12).toFixed(2) + " TB" : Math.round(b / 1e9) + " GB" }
    Process {
        id: load; running: pg.visible
        command: ["python3", "-I", Qt.resolvedUrl("sysinfo.py").toString().replace("file://", ""), "storage"]
        stdout: StdioCollector { onStreamFinished: { try { pg.st = JSON.parse(this.text) } catch (e) {} } }
    }
    Row {
        width: parent.width; spacing: 14
        Repeater {
            model: pg.st.drives
            Rectangle {
                id: dr
                required property var modelData
                width: (pg.width - 14) / 2; height: 96; radius: 2; color: Theme.card; border.width: 1; border.color: "#14eaeaea"
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                    Rectangle { width: 46; height: 46; radius: 2; color: dr.modelData.healthy ? Qt.rgba(0.78, 0.78, 0.78, 0.16) : Qt.rgba(0.81, 0.42, 0.42, 0.2)
                        Label { anchors.centerIn: parent; text: "\u{f02ca}"; color: dr.modelData.healthy ? Theme.green : Theme.red; font.pixelSize: 22 } }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        Label { text: dr.modelData.model; font.pixelSize: 13; font.weight: Font.Bold }
                        Label { text: (dr.modelData.healthy ? "Healthy" : "Warning – back up your files") + (dr.modelData.temp > 0 ? " · " + dr.modelData.temp + "°C" : ""); color: dr.modelData.healthy ? Theme.green : Theme.red; font.pixelSize: 11 }
                        Label { visible: dr.modelData.size > 0; text: pg.gb(dr.modelData.size); color: Theme.muted; font.pixelSize: 10 }
                    }
                }
            }
        }
    }
    SetSection {
        width: parent.width; title: "Space"; icon: "\u{f0a0a}"
        Repeater {
            model: pg.st.mounts
            Column {
                id: mt
                required property var modelData
                readonly property real pct: modelData.used / Math.max(1, modelData.size)
                width: parent.width; spacing: 6
                Row {
                    width: parent.width
                    Label { width: parent.width / 2; text: mt.modelData.mount === "/" ? "System (/)" : mt.modelData.mount.replace(Quickshell.env("HOME"), "~"); font.pixelSize: 12 }
                    Label { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: pg.gb(mt.modelData.free) + " free of " + pg.gb(mt.modelData.size); color: Theme.muted; font.pixelSize: 11 }
                }
                Rectangle {
                    width: parent.width; height: 10; radius: 5; color: Theme.bgAlt
                    Rectangle { width: parent.width * mt.pct; height: parent.height; radius: 5; color: mt.pct > 0.9 ? Theme.red : mt.pct > 0.75 ? Theme.yellow : Theme.blue }
                }
            }
        }
    }
    Row {
        spacing: 8
        SetButton { icon: "\u{f0a0a}"; text: "What's using space"; onClicked: Quickshell.execDetached(["filelight", Quickshell.env("HOME")]) }
        SetButton { icon: "\u{f00e8}"; text: "Clean package cache"
            onClicked: Quickshell.execDetached(["kitty", "--class", "updater", "-e", "bash", "-c", "echo 'Keeps the last 2 versions of each package, removes older ones.'; sudo paccache -rk2; yay -Sc --aur --noconfirm 2>/dev/null; echo; read -n1 -rsp 'Done – press any key'"]) }
        SetButton { icon: "\u{f0450}"; text: "Refresh"; onClicked: load.running = true }
    }
}
