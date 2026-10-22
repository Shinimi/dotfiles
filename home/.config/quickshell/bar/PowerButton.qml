// Power button + panel. Reboot / shutdown / logout need a second click. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell

Pill {
    property alias popup: panel
    id: pill
    padding: 10
    active: panel.visible
    Label { text: ""; color: pill.hovered ? "#ffffff" : Theme.fgDim; font.pixelSize: 14 }
    onClicked: panel.toggle()

    BarPopup {
        id: panel
        anchorItem: pill
        contentWidth: 250
        property string armed: ""
        onVisibleChanged: armed = ""
        Timer { id: disarm; interval: 3000; onTriggered: panel.armed = "" }

        Item {   // SESSION // 終了
            width: parent.width; height: 36
            Row {
                spacing: 8
                Text { text: "SESSION"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 3; font.bold: true }
                Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 12 }
                Text { text: "終了"; color: "#7a7a7a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 12 }
            }
            Text { y: 20; text: (Settings.cur("user_name") || Quickshell.env("USER")) + "  ·  CachyOS  ·  up " + Stats.d.uptime
                   color: "#6a6a6a"; font.family: Theme.font; font.pixelSize: 10 }
        }
        Rectangle { width: parent.width; height: 1; color: "#26ffffff" }

        Repeater {
            model: [
                { key: "lock",     icon: "\u{f033e}", text: "lock",      confirm: false, cmd: ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"] },
                { key: "suspend",  icon: "\u{f0904}", text: "sleep",     confirm: false, cmd: ["systemctl", "suspend"] },
                { key: "logout",   icon: "\u{f0343}", text: "log out",   confirm: true,  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                { key: "reboot",   icon: "\u{f0709}", text: "restart",   confirm: true,  cmd: ["systemctl", "reboot"] },
                { key: "shutdown", icon: "\u{f0425}", text: "shut down", confirm: true,  cmd: ["systemctl", "poweroff"] }
            ]
            Rectangle {
                required property var modelData
                required property int index
                readonly property bool armedHere: panel.armed === modelData.key
                width: parent.width; height: 38; radius: 2
                color: armedHere ? (modelData.key === "shutdown" ? Theme.red : Theme.on) : (rowMouse.containsMouse ? "#12ffffff" : "transparent")
                border.width: 1; border.color: armedHere ? "transparent" : (rowMouse.containsMouse ? "#40ffffff" : "#1affffff")
                Behavior on color { ColorAnimation { duration: 120 } }
                Rectangle { visible: rowMouse.containsMouse && !armedHere; width: 2; height: parent.height; color: "#ffffff" }
                Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: String(index + 1).padStart(2, "0")
                       color: armedHere ? "#66000000" : "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10 }
                Text { x: 38; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon
                       color: armedHere ? Theme.onText : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 14 }
                Text { x: 64; anchors.verticalCenter: parent.verticalCenter
                       text: (armedHere ? "again to " + modelData.text : modelData.text).toUpperCase()
                       color: armedHere ? Theme.onText : "#e8e8e8"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2; font.bold: armedHere }
                MouseArea {
                    id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.confirm && !armedHere) { panel.armed = modelData.key; disarm.restart(); return }
                        panel.visible = false
                        Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}
