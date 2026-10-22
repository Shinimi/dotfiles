// Emoji picker (SUPER + .), like Windows 11. Types the emoji into the focused app. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var all: []
    property var recent: []
    property string query: ""
    property string hoverName: ""
    readonly property string recentFile: Quickshell.env("HOME") + "/.local/state/emoji-recent.json"
    readonly property var shown: {
        const q = query.trim().toLowerCase()
        if (!q) return all
        const words = q.split(/\s+/)
        return all.filter(x => words.every(w => x.n.indexOf(w) >= 0))
    }

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; hoverName = ""; PopupState.current = root; loadRecent.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "emoji"; function toggle(): void { root.toggle() } }

    Process {
        running: true
        command: ["cat", Qt.resolvedUrl("emoji.json").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.all = JSON.parse(this.text) } catch (e) {} } }
    }
    Process {
        id: loadRecent
        command: ["cat", root.recentFile]
        stdout: StdioCollector { onStreamFinished: { try { root.recent = JSON.parse(this.text) } catch (e) { root.recent = [] } } }
    }

    function pick(e) {
        if (!e) return
        root.visible = false
        const r = [e].concat(recent.filter(x => x !== e)).slice(0, 16)
        recent = r
        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.local/state && printf '%s' \"$1\" > \"$2\"", "sh", JSON.stringify(r), recentFile])
        // wait for focus to return to the app, then type it (and keep it on the clipboard too)
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy; sleep 0.15; wtype \"$1\"", "sh", e])
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#44000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-emoji"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 460; implicitHeight: 520

        Rectangle {
            anchors.fill: parent; radius: 3; color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.94), Theme.tint, 0.07 * Theme.tintOn); border.width: 1; border.color: "#3dffffff"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                TextField {
                    id: search
                    Layout.fillWidth: true; Layout.preferredHeight: 42
                    focus: root.visible
                    onVisibleChanged: if (visible) forceActiveFocus()
                    text: root.query; onTextChanged: root.query = text
                    placeholderText: "Search emoji…"; placeholderTextColor: Theme.muted
                    color: Theme.fg; font.family: Theme.font; font.pixelSize: 14
                    leftPadding: 40
                    background: Rectangle { radius: 2; color: Theme.bgAlt; border.width: search.activeFocus ? 2 : 1; border.color: search.activeFocus ? Theme.blue : Theme.line }
                    Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: ""; color: Theme.muted }
                    Keys.onEscapePressed: root.visible = false
                    Keys.onReturnPressed: if (root.shown.length) root.pick(root.shown[0].e)
                }
                Column {
                    visible: root.query === "" && root.recent.length > 0
                    Layout.fillWidth: true; spacing: 6
                    Label { text: "Recent"; color: Theme.muted; font.pixelSize: 11 }
                    Flow {
                        width: parent.width; spacing: 2
                        Repeater {
                            model: root.recent
                            Rectangle {
                                required property var modelData
                                width: 42; height: 42; radius: 2
                                color: rMouse.containsMouse ? Theme.bgHover : "transparent"
                                Text { anchors.centerIn: parent; text: modelData; font.family: "Noto Color Emoji"; font.pixelSize: 24 }
                                MouseArea { id: rMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pick(modelData) }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.border }
                }
                GridView {
                    id: grid
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    cellWidth: Math.floor(width / 9); cellHeight: cellWidth
                    model: root.shown
                    cacheBuffer: 400
                    delegate: Rectangle {
                        required property var modelData
                        width: grid.cellWidth; height: grid.cellHeight; radius: 2
                        color: eMouse.containsMouse ? Theme.bgHover : "transparent"
                        Text { anchors.centerIn: parent; text: modelData.e; font.family: "Noto Color Emoji"; font.pixelSize: 24 }
                        MouseArea {
                            id: eMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: if (containsMouse) root.hoverName = modelData.n
                            onClicked: root.pick(modelData.e)
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: root.hoverName ? root.hoverName : (root.shown.length + " emoji · Enter picks the first")
                    color: Theme.muted; font.pixelSize: 11
                }
            }
        }
    }
}
