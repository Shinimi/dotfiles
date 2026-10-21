// Alt+Tab workspace switcher. Hold Alt, tap Tab (Shift+Tab back), release Alt to switch.
// Most-recently-used order, so one quick Alt+Tab returns to the previous workspace. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var mru: []            // workspace ids, most recent first
    property var cards: []          // [{id, windows:[{cls,title}]}]
    property int sel: 0

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const w = Hyprland.focusedWorkspace
            if (!w || w.id < 1) return
            root.mru = [w.id].concat(root.mru.filter(x => x !== w.id))
        }
    }
    Component.onCompleted: if (Hyprland.focusedWorkspace) mru = [Hyprland.focusedWorkspace.id]

    function open(step) {
        clients.step = step
        clients.running = true
    }
    function move(step) {
        if (!visible) { open(step); return }
        if (cards.length) sel = (sel + step + cards.length) % cards.length
    }
    function confirm() {
        if (!visible) return
        visible = false
        const c = cards[sel]
        if (c) Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + c.id + " })"])
    }
    function cancel() { visible = false }

    Process {
        id: clients
        property int step: 1
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(this.text) } catch (e) {}
                const byWs = {}
                for (const c of list) {
                    const id = c.workspace ? c.workspace.id : -1
                    if (id < 1) continue
                    ;(byWs[id] = byWs[id] || []).push({ cls: c.class || c.initialClass || "", title: c.title || "" })
                }
                const cur = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
                const ids = Object.keys(byWs).map(Number)
                if (!ids.includes(cur)) ids.push(cur)
                ids.sort((a, b) => {
                    const ia = root.mru.indexOf(a), ib = root.mru.indexOf(b)
                    return (ia < 0 ? 999 + a : ia) - (ib < 0 ? 999 + b : ib)
                })
                root.cards = ids.map(id => ({ id: id, windows: byWs[id] || [] }))
                root.sel = root.cards.length > 1 ? (clients.step > 0 ? 1 : root.cards.length - 1) : 0
                root.visible = true
            }
        }
    }

    IpcHandler {
        target: "alttab"
        function next(): void { root.move(1) }
        function prev(): void { root.move(-1) }
        function confirm(): void { root.confirm() }
        function cancel(): void { root.cancel() }
    }

    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls)
        const name = e && e.icon ? e.icon : cls.toLowerCase()
        return Quickshell.iconPath(name, true) || Quickshell.iconPath("application-x-executable")
    }

    PanelWindow {
        visible: root.visible
        screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-alttab"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: Math.min(row.implicitWidth + 40, 1800)
        implicitHeight: 230

        Rectangle {
            anchors.fill: parent; radius: 18; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { root.move(1); e.accepted = true }
                else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { root.move(-1); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.confirm(); e.accepted = true }
                else if (e.key === Qt.Key_Escape) { root.cancel(); e.accepted = true }
            }
            Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr) root.confirm() }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 14
                Repeater {
                    model: root.cards
                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === root.sel
                        width: 200; height: 180; radius: 14
                        color: selected ? "#4d7aa2f7" : Theme.card
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.blue : Theme.border
                        scale: selected ? 1.0 : 0.94
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 110 } }

                        Column {
                            anchors.fill: parent; anchors.margins: 14; spacing: 10
                            RowLayout {
                                width: parent.width
                                Rectangle {
                                    width: 30; height: 30; radius: 8
                                    color: selected ? Theme.blue : Theme.bg
                                    Label { anchors.centerIn: parent; text: modelData.id; color: selected ? Theme.bg : Theme.fg; font.pixelSize: 15; font.weight: Font.Bold }
                                }
                                Label {
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                                    text: modelData.windows.length === 0 ? "empty" : modelData.windows.length + (modelData.windows.length === 1 ? " window" : " windows")
                                    color: Theme.muted; font.pixelSize: 11
                                }
                            }
                            Flow {
                                width: parent.width; spacing: 8
                                height: 44
                                Repeater {
                                    model: modelData.windows.slice(0, 4)
                                    IconImage { required property var modelData; implicitSize: 40; source: root.iconFor(modelData.cls) }
                                }
                                Label { visible: modelData.windows.length === 0; text: ""; color: Theme.line; font.pixelSize: 9 }
                            }
                            Label {
                                width: parent.width
                                text: modelData.windows.length ? modelData.windows[0].title : "Nothing open here"
                                color: selected ? Theme.fg : Theme.fgDim; elide: Text.ElideRight; font.weight: Font.Normal
                            }
                            Label {
                                visible: modelData.windows.length > 1
                                width: parent.width
                                text: modelData.windows.slice(1).map(w => w.cls).join(" · ")
                                color: Theme.muted; elide: Text.ElideRight; font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.sel = index; root.confirm() }
                        }
                    }
                }
            }
        }
    }
}
