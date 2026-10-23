// Settings → Shortcuts: every keyboard shortcut, searchable. Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "."   // our own Label (Geist Mono) wins over the Qt Controls one

Column {
    id: pg
    spacing: 12
    property var all: []
    property string q: ""
    readonly property var shown: q ? all.filter(x => (x.k + " " + x.d).toLowerCase().indexOf(q.toLowerCase()) >= 0) : all
    Process {
        running: pg.visible
        command: ["sh", "-c", "awk '/KEYBINDS/{f=1;next} f && /^-- =====/{exit} f && /^--/' \"$HOME/.config/hypr/hyprland.lua\" | sed 's/^--  *//'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of this.text.split("\n")) {
                    if (!line.trim() || line.trim().startsWith("(")) continue
                    const parts = line.split(/\s{2,}/).map(x => x.trim()).filter(x => x)
                    for (let i = 0; i + 1 < parts.length; i += 2) out.push({ k: parts[i], d: parts[i + 1] })
                }
                pg.all = out
            }
        }
    }
    TextField {
        id: f
        width: parent.width; height: 40
        placeholderText: "Search shortcuts…  (e.g. screenshot, workspace, lock)"; placeholderTextColor: Theme.muted
        onTextEdited: pg.q = text
        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 12
        background: Rectangle { radius: 14; color: "#1c1c1c"; border.width: 1; border.color: f.activeFocus ? "#55ffffff" : "transparent" }
    }
    Grid {
        width: parent.width; columns: 2; columnSpacing: 10; rowSpacing: 6
        Repeater {
            model: pg.shown
            Rectangle {
                required property var modelData
                width: (pg.width - 10) / 2; height: 38; radius: 14; color: "#1a1a1a"
                Rectangle {
                    x: 8; anchors.verticalCenter: parent.verticalCenter; height: 26; radius: 7; width: Math.min(kl.implicitWidth + 16, parent.width * 0.55)
                    color: Qt.rgba(0.88, 0.88, 0.88, 0.16); clip: true
                    Label { id: kl; x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.k.replace(/SUPER/g, "\u{f17a} "); color: Theme.blue; font.pixelSize: 10 }
                }
                Label { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.4; horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight; text: modelData.d; color: Theme.fgDim; font.pixelSize: 11 }
            }
        }
    }
}
