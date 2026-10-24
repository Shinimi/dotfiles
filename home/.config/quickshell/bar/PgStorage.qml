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
                width: (pg.width - 14) / 2; height: 96; radius: 22; color: "#131313"
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                    Rectangle { width: 46; height: 46; radius: 12; color: dr.modelData.healthy ? Qt.rgba(0.78, 0.78, 0.78, 0.16) : Qt.rgba(0.81, 0.42, 0.42, 0.2)
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
    SetHeading { text: "Space"; icon: "\u{f0a0a}" }
    Row {   // a ring per drive: how full it is
        width: parent.width; spacing: 14
        Repeater {
            model: pg.st.mounts
            Rectangle {
                id: mt
                required property var modelData
                readonly property real pct: modelData.used / Math.max(1, modelData.size)
                width: (pg.width - 14 * (pg.st.mounts.length - 1)) / Math.max(1, pg.st.mounts.length); height: 150; radius: 16
                color: "#131313"; border.width: 1; border.color: pct > 0.9 ? "#cf6b6b" : "#1d1d1d"
                Canvas {
                    x: 18; anchors.verticalCenter: parent.verticalCenter; width: 104; height: 104
                    property real v: mt.pct
                    onVChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        c.lineWidth = 10; c.lineCap = "round"
                        c.strokeStyle = "rgba(255,255,255,0.07)"; c.beginPath(); c.arc(52, 52, 44, 0, 2 * Math.PI); c.stroke()
                        c.strokeStyle = v > 0.9 ? "#cf6b6b" : "#ececec"; c.beginPath(); c.arc(52, 52, 44, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v); c.stroke()
                    }
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(mt.pct * 100) + "%"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 20; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "used"; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 9 }
                    }
                }
                Column {
                    x: 140; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 156; spacing: 4
                    Text { width: parent.width; elide: Text.ElideRight; text: mt.modelData.mount === "/" ? "System" : mt.modelData.mount.split("/").pop()
                           color: "#ececec"; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                    Text { width: parent.width; elide: Text.ElideRight; text: mt.modelData.mount.replace(Quickshell.env("HOME"), "~"); color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 10 }
                    Item { width: 1; height: 6 }
                    Text { text: pg.gb(mt.modelData.free) + " free"; color: "#d8d8d8"; font.family: Theme.font; font.pixelSize: 12 }
                    Text { text: pg.gb(mt.modelData.used) + " of " + pg.gb(mt.modelData.size) + " used"; color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }
    SetSection {
        visible: false; width: parent.width; title: "Space"; icon: "\u{f0a0a}"
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
