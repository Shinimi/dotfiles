// Settings → Account: your picture and name (used in the control center, lock and login screens). Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property var pics: []
    Process {
        id: list; running: pg.visible
        command: ["python3", "-I", Qt.resolvedUrl("sysinfo.py").toString().replace("file://", ""), "avatars"]
        stdout: StdioCollector { onStreamFinished: { try { pg.pics = JSON.parse(this.text) } catch (e) {} } }
    }
    Process {
        id: browse
        command: ["kdialog", "--title", "Choose your picture", "--getopenfilename", Quickshell.env("HOME") + "/Pictures", "Images (*.png *.jpg *.jpeg *.webp)"]
        stdout: StdioCollector { onStreamFinished: { const p = this.text.trim(); if (p) Settings.set("avatar", p) } }
    }

    Rectangle {
        width: parent.width; height: 150; radius: 18; color: Theme.card; border.width: 1; border.color: "#14efeaf8"
        Row {
            x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 22
            Avatar { size: 104; pick: Settings.get("avatar"); radius: 52 }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Label { text: Settings.get("user_name") || Quickshell.env("USER"); font.pixelSize: 24; font.weight: Font.Bold }
                Label { text: Quickshell.env("USER") + "@cachyos"; color: Theme.blue; font.pixelSize: 12 }
                Label { text: "Shown in the control center, lock screen and login screen"; color: Theme.muted; font.pixelSize: 11 }
            }
        }
    }
    Row {
        width: parent.width; spacing: 14
        SetSection {
            width: (parent.width - 14) / 2; title: "Name"; icon: "\u{f0004}"
            SetField { label: "Display name"; key: "user_name"; placeholder: Quickshell.env("USER"); desc: "Used in greetings like \"Good evening, …\"" }
            SetChoice {
                label: "Control center picture"; current: Settings.get("cc_logo"); onPicked: v => Settings.set("cc_logo", v)
                options: [["avatar", "My picture"], ["logo", "CachyOS logo"]]
            }
        }
        SetSection {
            width: (parent.width - 14) / 2; title: "Picture"; icon: "\u{f0e1a}"
            Label { width: parent.width; wrapMode: Text.WordWrap; text: "Pick one below, or choose any image from your computer."; color: Theme.muted; font.pixelSize: 11 }
            Row {
                spacing: 8
                SetButton { icon: "\u{f0256}"; text: "Browse…"; onClicked: browse.running = true }
                SetButton { icon: "\u{f0156}"; text: "Remove"; accent: Theme.red; visible: Settings.get("avatar") !== ""; onClicked: Settings.set("avatar", "") }
            }
        }
    }
    SetSection {
        width: parent.width; title: "Your pictures"; icon: "\u{f02e9}"
        Flow {
            width: parent.width; spacing: 8
            Repeater {
                model: pg.pics
                Rectangle {
                    id: pc
                    required property string modelData
                    readonly property bool cur: Settings.get("avatar") === modelData
                    width: 64; height: 64; radius: 16; color: Theme.bgAlt
                    border.width: cur ? 3 : (pm.containsMouse ? 1 : 0); border.color: cur ? Theme.blue : Theme.line
                    Avatar { anchors.centerIn: parent; size: 58; pick: pc.modelData; radius: 14 }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("avatar", pc.modelData) }
                }
            }
        }
    }
}
