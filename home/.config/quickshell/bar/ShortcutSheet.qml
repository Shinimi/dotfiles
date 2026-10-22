// Shortcut sheet (SUPER + F1 or SUPER + Shift + /): every keyboard shortcut, numbered, in three columns.
// Read live from the KEYBINDS block at the top of hyprland.lua. Type to filter · Esc closes. Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."   // our own Label (Geist Mono) wins over the Qt Controls one

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var all: []
    property string q: ""
    readonly property var shown: q ? all.filter(x => (x.k + " " + x.d).toLowerCase().indexOf(q.toLowerCase()) >= 0) : all
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { PopupState.current = root; load.running = true; q = "" }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "keys"; function toggle(): void { root.toggle() } }

    Process {
        id: load
        command: ["sh", "-c", "awk '/KEYBINDS/{f=1;next} f && /^-- =====/{exit} f && /^--/' \"$HOME/.config/hypr/hyprland.lua\" | sed 's/^--  *//'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of this.text.split("\n")) {
                    if (!line.trim() || line.trim().startsWith("(")) continue
                    const parts = line.split(/\s{2,}/).map(x => x.trim()).filter(x => x)
                    for (let i = 0; i + 1 < parts.length; i += 2) out.push({ k: parts[i], d: parts[i + 1] })
                }
                root.all = out
            }
        }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-keys"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: Theme.mix(Qt.rgba(0.015, 0.015, 0.015, 0.93), Theme.tint, 0.06 * Theme.tintOn)
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }

        Item {
            id: box
            anchors.centerIn: parent
            width: Math.min(parent.width - 160, 1700); height: parent.height - 200

            Row {
                id: head
                spacing: 12
                Text { text: "SHORTCUTS"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 18; font.letterSpacing: 4; font.bold: true }
                Text { anchors.baseline: parent.children[0].baseline; text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 14 }
                Text { anchors.baseline: parent.children[0].baseline; text: "近道"; color: "#7a7a7a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 15 }
                Text { anchors.baseline: parent.children[0].baseline; leftPadding: 18; text: root.shown.length + " / " + root.all.length + " KEYS"
                       color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
            }
            TextField {
                id: find
                anchors.right: parent.right; y: -4; width: 360; height: 36
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) { find.text = ""; find.forceActiveFocus() } } }
                onTextChanged: root.q = text
                placeholderText: "filter…"; placeholderTextColor: "#555555"
                color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 13; leftPadding: 28
                background: Rectangle { radius: 2; color: "#0cffffff"; border.width: 1; border.color: find.activeFocus ? "#77ffffff" : "#26ffffff"
                                        Rectangle { width: 2; height: parent.height; color: "#ffffff" } }
                Text { x: 11; anchors.verticalCenter: parent.verticalCenter; text: "›"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 15 }
                Keys.onEscapePressed: root.visible = false
            }
            Rectangle { y: head.height + 18; width: parent.width; height: 1; color: "#26ffffff" }

            Flickable {
                y: head.height + 34; width: parent.width; height: parent.height - y
                contentHeight: grid.height; clip: true; boundsBehavior: Flickable.StopAtBounds
                MouseArea { width: parent.width; height: Math.max(parent.height, grid.height) }   // clicks here don't close
                Grid {
                    id: grid
                    width: parent.width; columns: 3; columnSpacing: 40; rowSpacing: 2
                    flow: Grid.TopToBottom
                    rows: Math.ceil(root.shown.length / 3)
                    Repeater {
                        model: root.shown
                        Item {
                            required property var modelData
                            required property int index
                            width: (grid.width - 80) / 3; height: 34
                            Rectangle { anchors.fill: parent; color: hm.containsMouse ? "#0dffffff" : "transparent" }
                            Text { x: 6; anchors.verticalCenter: parent.verticalCenter; text: String(index + 1).padStart(2, "0")
                                   color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10 }
                            Row {
                                id: keyRow
                                x: 34; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Repeater {
                                    model: modelData.k.split(/\s*\+\s*/)
                                    Rectangle {
                                        required property string modelData
                                        width: kt.implicitWidth + 14; height: 22; radius: 2
                                        color: "transparent"; border.width: 1; border.color: "#40ffffff"
                                        Text { id: kt; anchors.centerIn: parent; text: modelData; color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 10; font.bold: true }
                                    }
                                }
                            }
                            Text {
                                anchors.left: keyRow.right; anchors.leftMargin: 14; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight; text: modelData.d; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 11
                            }
                            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
        }
    }
}
