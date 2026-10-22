// Power button + panel. Reboot / shutdown / logout need a second click. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell

Pill {
    property alias popup: panel
    id: pill
    padding: 10
    active: panel.visible
    Label { text: ""; color: pill.hovered ? Theme.red : Theme.fgDim; font.pixelSize: 14 }
    onClicked: panel.toggle()

    BarPopup {
        id: panel
        anchorItem: pill
        contentWidth: 230
        property string armed: ""
        onVisibleChanged: armed = ""
        Timer { id: disarm; interval: 3000; onTriggered: panel.armed = "" }

        Column {
            width: parent.width; spacing: 2
            Label { text: "Session"; font.pixelSize: 15; font.weight: Font.Bold }
            Label { text: Quickshell.env("USER") + " · CachyOS"; color: Theme.muted; font.pixelSize: 11 }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border }

        Repeater {
            model: [
                { key: "lock",     icon: "", text: "Lock",      color: Theme.blue,   confirm: false, cmd: ["loginctl", "lock-session"] },
                { key: "suspend",  icon: "", text: "Suspend",   color: Theme.purple, confirm: false, cmd: ["systemctl", "suspend"] },
                { key: "logout",   icon: "", text: "Log out",   color: Theme.yellow, confirm: true,  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                { key: "reboot",   icon: "", text: "Reboot",    color: Theme.cyan,   confirm: true,  cmd: ["systemctl", "reboot"] },
                { key: "shutdown", icon: "", text: "Shut down", color: Theme.red,    confirm: true,  cmd: ["systemctl", "poweroff"] }
            ]
            Rectangle {
                required property var modelData
                readonly property bool armedHere: panel.armed === modelData.key
                width: parent.width; height: 38; radius: 10
                color: armedHere ? modelData.color : (rowMouse.containsMouse ? Theme.bgHover : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                    Label { text: modelData.icon; color: armedHere ? Theme.bg : modelData.color; font.pixelSize: 15; Layout.preferredWidth: 18 }
                    Label { text: armedHere ? "Click again to " + modelData.text.toLowerCase() : modelData.text
                            color: armedHere ? Theme.bg : Theme.fg; Layout.fillWidth: true }
                }
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
