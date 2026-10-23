// Power button + menu: five round buttons in a row. Log out / restart / power off ask once more
// (the button turns white, a ring breathes around it and it says "sure?"). Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Pill {
    property alias popup: panel
    id: pill
    implicitWidth: 34
    active: panel.visible
    Label { text: "\uf011"; color: pill.hovered ? "#ffffff" : Theme.fg; font.pixelSize: 15 }
    property bool menu: true             // false: open the main screen's menu instead (side screen bar)
    onClicked: menu ? panel.toggle() : Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "bar", "power"])

    BarPopup {
        id: panel
        anchorItem: pill
        contentWidth: 344
        padding: 20
        property string armed: ""
        onVisibleChanged: armed = ""
        Timer { id: disarm; interval: 3000; onTriggered: panel.armed = "" }

        RowLayout {   // who + how long
            width: parent.width; spacing: 12
            ClippingRectangle {
                width: 40; height: 40; radius: 20; color: "#161616"
                Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 96; asynchronous: true
                        source: Settings.cur("avatar") ? "file://" + Settings.cur("avatar") : "file://" + Quickshell.env("HOME") + "/.face" }
            }
            Column {
                Layout.fillWidth: true; spacing: 3
                Text { text: panel.armed ? "click again to confirm" : "see you, " + (Settings.cur("user_name") || "yu").toLowerCase()
                       color: "#ffffff"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                Text { text: "up " + Stats.d.uptime; color: "#6e6e6e"; font.family: Theme.font; font.pixelSize: 11 }
            }
        }

        Item { width: 1; height: 4 }

        Row {
            spacing: (parent.width - 5 * 56) / 4
            Repeater {
                model: [
                    { key: "lock",     icon: "\u{f033e}", text: "lock",      confirm: false, cmd: ["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "curtain", "lock"] },
                    { key: "suspend",  icon: "\u{f0904}", text: "sleep",     confirm: false, cmd: ["systemctl", "suspend"] },
                    { key: "logout",   icon: "\u{f0343}", text: "log out",   confirm: true,  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                    { key: "reboot",   icon: "\u{f0709}", text: "restart",   confirm: true,  cmd: ["systemctl", "reboot"] },
                    { key: "shutdown", icon: "\u{f0425}", text: "power off", confirm: true,  cmd: ["systemctl", "poweroff"] }
                ]
                Column {
                    id: btn
                    required property var modelData
                    readonly property bool armedHere: panel.armed === modelData.key
                    readonly property bool lit: armedHere || bm.containsMouse
                    width: 56; spacing: 9
                    Rectangle {
                        width: 56; height: 56; radius: 28
                        color: btn.lit ? "#ececec" : "#161616"
                        scale: bm.pressed ? 0.93 : 1
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Rectangle {   // armed: a ring that breathes until you confirm or it times out
                            anchors.centerIn: parent; width: parent.width + 10; height: width; radius: width / 2
                            color: "transparent"; border.width: 1; border.color: "#ececec"
                            visible: btn.armedHere
                            SequentialAnimation on opacity {
                                running: btn.armedHere; loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 0.15; duration: 650 }
                                NumberAnimation { from: 0.15; to: 1; duration: 650 }
                            }
                        }
                        Text { anchors.centerIn: parent; text: btn.modelData.icon; font.family: Theme.font; font.pixelSize: 19
                               color: btn.lit ? "#0b0b0b" : "#e6e6e6" }
                        MouseArea {
                            id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (btn.modelData.confirm && Settings.cur("confirm_power") && !btn.armedHere) { panel.armed = btn.modelData.key; disarm.restart(); return }
                                panel.visible = false
                                Quickshell.execDetached(btn.modelData.cmd)
                            }
                        }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: btn.armedHere ? "sure?" : btn.modelData.text
                           color: btn.armedHere ? "#ffffff" : (bm.containsMouse ? "#e6e6e6" : "#7a7a7a")
                           font.family: Theme.font; font.pixelSize: 10; font.bold: btn.armedHere }
                }
            }
        }
    }
}
