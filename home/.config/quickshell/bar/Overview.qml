// Workspace overview (SUPER + Tab): every workspace with live window previews.
// Click a workspace to go there · drag a window onto another workspace to move it · Esc closes. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var clients: []
    readonly property int curWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // workspaces 1–4 always, plus any other main-screen workspace that has windows or is active
    readonly property var wsIds: {
        const ids = [1, 2, 3, 4]
        for (const c of clients) if (c.workspace.id > 0 && c.monitor === 0 && ids.indexOf(c.workspace.id) < 0) ids.push(c.workspace.id)
        if (curWs > 0 && ids.indexOf(curWs) < 0) ids.push(curWs)
        return ids.sort((a, b) => a - b)
    }
    readonly property real mw: screen ? screen.width : 2560
    readonly property real mh: screen ? screen.height : 1440
    readonly property real tileW: 470
    readonly property real k: tileW / mw

    function toggle() { if (visible) visible = false; else load.running = true }
    function go(id) { visible = false; Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + id + "\" })"]) }
    function moveTo(addr, id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ window = \"address:" + addr + "\", workspace = \"" + id + "\", follow = false })"])
        refresh.restart()
    }
    function toplevelFor(addr) {
        const a = addr.replace(/^0x/, "").toLowerCase()
        for (const t of Hyprland.toplevels.values) if (String(t.address).replace(/^0x/, "").toLowerCase() === a) return t.wayland
        return null
    }
    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls)
        return Quickshell.iconPath(e && e.icon ? e.icon : cls.toLowerCase(), true) || Quickshell.iconPath("application-x-executable")
    }

    Process {
        id: load
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.clients = JSON.parse(this.text).filter(c => c.mapped !== false) } catch (e) {} root.visible = true } }
    }
    Timer { id: refresh; interval: 250; onTriggered: load.running = true }
    IpcHandler { target: "overview"; function toggle(): void { root.toggle() } }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-overview"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "#e60b0b0b"

        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
        Item {
            anchors.fill: parent; focus: root.visible
            Keys.onEscapePressed: root.visible = false
            Keys.onPressed: e => { const n = e.key - Qt.Key_0; if (n >= 1 && n <= 9) root.go(n) }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 70
            text: "w o r k s p a c e s"; color: Theme.purple; font.family: Theme.font; font.pixelSize: 15
        }

        Flow {
            id: grid
            anchors.centerIn: parent
            width: Math.min(root.wsIds.length, 4) * (root.tileW + 26) - 26
            spacing: 26
            Repeater {
                model: root.wsIds
                Item {
                    id: tile
                    required property int modelData
                    readonly property bool cur: modelData === root.curWs
                    width: root.tileW; height: root.mh * root.k + 30
                    Rectangle {
                        id: frame
                        width: parent.width; height: root.mh * root.k; radius: 14; clip: true
                        color: Theme.bgAlt
                        border.width: drop.containsDrag ? 3 : (tile.cur ? 2 : 1)
                        border.color: drop.containsDrag ? Theme.purple : (tile.cur ? Theme.blue : "#22eaeaea")
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.go(tile.modelData) }
                        DropArea { id: drop; anchors.fill: parent; onDropped: d => root.moveTo(d.source.addr, tile.modelData) }

                        Repeater {
                            model: root.clients.filter(c => c.workspace.id === tile.modelData && c.monitor === 0)
                            Rectangle {
                                id: win
                                required property var modelData
                                property string addr: modelData.address
                                x: modelData.at[0] * root.k; y: (modelData.at[1]) * root.k
                                width: Math.max(24, modelData.size[0] * root.k); height: Math.max(18, modelData.size[1] * root.k)
                                radius: 6; color: Theme.bg; clip: true
                                border.width: 1; border.color: dm.containsMouse ? Theme.purple : "#33eaeaea"
                                Drag.active: dm.drag.active; Drag.source: win; Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: root.visible ? root.toplevelFor(win.modelData.address) : null
                                    live: false
                                }
                                IconImage { anchors.centerIn: parent; implicitSize: Math.min(36, parent.height * 0.5); source: root.iconFor(win.modelData.class || ""); opacity: 0.9 }
                                MouseArea {
                                    id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.OpenHandCursor
                                    drag.target: win
                                    onReleased: { if (win.Drag.active) win.Drag.drop(); win.x = win.modelData.at[0] * root.k; win.y = win.modelData.at[1] * root.k }
                                    onClicked: { root.visible = false; Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + win.addr + "\" })"]) }
                                }
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                        text: tile.modelData; color: tile.cur ? Theme.blue : Theme.muted
                        font.family: Theme.font; font.pixelSize: 13; font.bold: tile.cur
                    }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 60
            text: "click to go  ·  drag a window to move it  ·  1–9 jumps  ·  esc closes"
            color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
        }
    }
}
