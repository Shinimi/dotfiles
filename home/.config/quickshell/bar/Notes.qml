// Quick notes (SUPER + N): a drawer that slides in from the right. Type + Enter adds a note, click the box to
// tick it off, ✕ deletes (with undo for a few seconds). Saves itself to ~/.local/state/quick-notes.json.
// Esc or click outside closes. Made by Claude.
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
    property bool shown: false                  // keeps the window up while it slides out
    property var notes: []                      // [{id, text, done, t}]
    property var undo: null                     // {note, index}
    readonly property string file: Quickshell.env("HOME") + "/.local/state/quick-notes.json"
    function toggle() { visible = !visible }
    onVisibleChanged: { if (visible) { shown = true; PopupState.current = root; load.running = true } else hideLater.restart() }
    Timer { id: hideLater; interval: 280; onTriggered: if (!root.visible) root.shown = false }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "notes"; function toggle(): void { root.toggle() } }

    Process { id: load; command: ["cat", root.file]
              stdout: StdioCollector { onStreamFinished: { try { root.notes = JSON.parse(this.text) } catch (e) { root.notes = [] } } } }
    function save() { Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(notes), file]) }
    function add(text) {
        text = text.trim(); if (!text) return
        notes = [{ id: Date.now(), text: text, done: false, t: Qt.formatDateTime(new Date(), "d MMM HH:mm") }].concat(notes); save()
    }
    function tick(i) { const n = notes.slice(); n[i] = Object.assign({}, n[i], { done: !n[i].done }); notes = n; save() }
    function remove(i) { const n = notes.slice(); undo = { note: n[i], index: i }; n.splice(i, 1); notes = n; save(); undoTimer.restart() }
    function restore() { if (!undo) return; const n = notes.slice(); n.splice(Math.min(undo.index, n.length), 0, undo.note); notes = n; undo = null; save() }
    function clearDone() { notes = notes.filter(x => !x.done); save() }
    Timer { id: undoTimer; interval: 6000; onTriggered: root.undo = null }

    PanelWindow {
        visible: root.shown; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-notes"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }

        Rectangle {
            id: drawer
            width: 440; height: parent.height - 80
            y: 50
            x: root.visible ? parent.width - width - 18 : parent.width + 20
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            radius: 3; color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.95), Theme.tint, 0.07 * Theme.tintOn)
            border.width: 1; border.color: "#3dffffff"
            MouseArea { anchors.fill: parent }   // clicks inside stay inside

            Row {
                id: head; x: 20; y: 18; spacing: 12
                Text { text: "NOTES"; color: "#f2f2f2"; font.family: Theme.font; font.pixelSize: 13; font.letterSpacing: 4; font.bold: true }
                Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 13 }
                Text { text: "覚書"; color: "#7a7a7a"; font.family: "Noto Sans CJK JP"; font.pixelSize: 13 }
            }
            Text { anchors.right: parent.right; anchors.rightMargin: 20; y: 21
                   text: root.notes.filter(n => !n.done).length + " OPEN"; color: "#5a5a5a"; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
            Rectangle { x: 1; y: 52; width: parent.width - 2; height: 1; color: "#26ffffff" }

            TextField {
                id: input
                x: 16; y: 66; width: parent.width - 32; height: 40
                focus: root.visible
                Connections { target: root; function onVisibleChanged() { if (root.visible) input.forceActiveFocus() } }
                placeholderText: "new note…  (enter adds)"; placeholderTextColor: "#555555"
                color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 13; leftPadding: 28
                background: Rectangle { radius: 2; color: "#0cffffff"; border.width: 1; border.color: input.activeFocus ? "#77ffffff" : "#26ffffff"
                                        Rectangle { width: 2; height: parent.height; color: "#ffffff" } }
                Text { x: 11; anchors.verticalCenter: parent.verticalCenter; text: "+"; color: "#9a9a9a"; font.family: Theme.font; font.pixelSize: 15 }
                Keys.onReturnPressed: { root.add(text); text = "" }
                Keys.onEnterPressed: { root.add(text); text = "" }
                Keys.onEscapePressed: root.visible = false
            }

            ListView {
                id: lv
                x: 16; y: 118; width: parent.width - 32; height: parent.height - y - foot.height - 8
                clip: true; spacing: 4; model: root.notes; boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: lv.width; height: Math.max(48, nt.implicitHeight + 28); radius: 2
                    color: rm.containsMouse ? "#0fffffff" : "transparent"
                    border.width: 1; border.color: "#1affffff"
                    Text { x: 10; y: 14; text: String(row.index + 1).padStart(2, "0"); color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 10 }
                    Rectangle {   // tick box
                        x: 36; y: 13; width: 16; height: 16; radius: 1
                        color: row.modelData.done ? Theme.on : "transparent"; border.width: 1; border.color: row.modelData.done ? Theme.on : "#66ffffff"
                        Text { font.family: Theme.font; anchors.centerIn: parent; visible: row.modelData.done; text: "✓"; color: Theme.onText; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.tick(row.index) }
                    }
                    Text {
                        id: nt
                        x: 64; y: 12; width: parent.width - 64 - 40
                        text: row.modelData.text; wrapMode: Text.Wrap
                        color: row.modelData.done ? "#5a5a5a" : "#e8e8e8"; font.strikeout: row.modelData.done
                        font.family: Theme.font; font.pixelSize: 13
                    }
                    Text { x: 64; anchors.bottom: parent.bottom; anchors.bottomMargin: 5; text: row.modelData.t || ""; color: "#454545"; font.family: Theme.font; font.pixelSize: 9 }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 12; y: 12
                        text: "\u{f0156}"; color: dm.containsMouse ? "#ffffff" : "#5a5a5a"; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { id: dm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.remove(row.index) }
                    }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
                Text { anchors.centerIn: parent; visible: root.notes.length === 0; text: "nothing written down yet"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 12 }
            }

            Item {
                id: foot
                anchors.bottom: parent.bottom; width: parent.width; height: 44
                Rectangle { x: 1; width: parent.width - 2; height: 1; color: "#26ffffff" }
                Rectangle {   // undo after a delete
                    visible: root.undo !== null
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: ul.implicitWidth + 22; height: 26; radius: 2; color: Theme.on
                    Text { id: ul; anchors.centerIn: parent; text: "DELETED · UNDO"; color: Theme.onText; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.restore() }
                }
                Rectangle {
                    visible: root.notes.some(n => n.done)
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: cl.implicitWidth + 22; height: 26; radius: 2
                    color: cm.containsMouse ? "#14ffffff" : "transparent"; border.width: 1; border.color: "#33ffffff"
                    Text { id: cl; anchors.centerIn: parent; text: "CLEAR DONE"; color: "#a0a0a0"; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearDone() }
                }
            }
        }
    }
}
