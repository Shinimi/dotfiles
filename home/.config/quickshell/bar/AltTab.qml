// Window switcher with live previews, like Windows.
//   Alt+Tab (hold Alt)   : most-recently-used windows; tap Tab to move, release Alt to switch.
//   Super+Tab            : same list, stays open; type to search, Enter/click to switch, Esc to close.
// Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    required property var screen
    property bool visible: false
    property bool sticky: false        // Super+Tab mode (doesn't close on Alt release)
    property var wins: []              // [{address, cls, title, ws, wsName}]
    property int sel: 0
    property string query: ""
    readonly property var shown: {
        const q = query.trim().toLowerCase()
        return q ? wins.filter(w => (w.title + " " + w.cls).toLowerCase().indexOf(q) >= 0) : wins
    }
    onShownChanged: if (sel >= shown.length) sel = Math.max(0, shown.length - 1)

    function load(step, stick) {
        sticky = stick; query = ""
        clients.step = step
        clients.running = true
    }
    function move(step) {
        if (!visible) { load(step, false); return }
        if (shown.length) sel = (sel + step + shown.length) % shown.length
    }
    function confirm() {
        if (!visible) return
        visible = false
        const w = shown[sel]
        if (w) Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + w.address + "\" })"])
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
                list = list.filter(c => c.mapped !== false && c.workspace && c.workspace.id !== -1 && (c.title || c.class))
                list.sort((a, b) => a.focusHistoryID - b.focusHistoryID)       // most recent first
                root.wins = list.map(c => ({ address: c.address, cls: c.class || c.initialClass || "", title: c.title || c.class,
                                             ws: c.workspace.id, wsName: c.workspace.name }))
                root.sel = root.wins.length > 1 ? (root.sticky ? 0 : (clients.step > 0 ? 1 : root.wins.length - 1)) : 0
                root.visible = root.wins.length > 0
            }
        }
    }

    IpcHandler {
        target: "alttab"
        function next(): void { root.move(1) }
        function prev(): void { root.move(-1) }
        function confirm(): void { root.confirm() }
        function cancel(): void { root.cancel() }
        function overview(): void { if (root.visible) root.cancel(); else root.load(0, true) }
    }

    function toplevelFor(addr) {
        const a = addr.replace(/^0x/, "").toLowerCase()
        for (const t of Hyprland.toplevels.values) if (String(t.address).replace(/^0x/, "").toLowerCase() === a) return t.wayland
        return null
    }
    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls)
        const name = e && e.icon ? e.icon : cls.toLowerCase()
        return Quickshell.iconPath(name, true) || Quickshell.iconPath("application-x-executable")
    }

    PanelWindow {   // dim + click outside to close
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#55000000"
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }
    }

    PanelWindow {
        id: win
        visible: root.visible
        screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-alttab"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        readonly property int perRow: Math.min(5, Math.max(1, root.shown.length))
        implicitWidth: Math.max(520, perRow * 300 + (perRow - 1) * 14 + 48)
        implicitHeight: grid.implicitHeight + (root.sticky ? 112 : 48)

        Rectangle {
            id: frame
            anchors.fill: parent; radius: 3; color: Theme.mix(Qt.rgba(0.035, 0.035, 0.035, 0.94), Theme.tint, 0.07 * Theme.tintOn); border.width: 1; border.color: "#3dffffff"
            Brackets {}
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { root.move(1); e.accepted = true }
                else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { root.move(-1); e.accepted = true }
                else if (e.key === Qt.Key_Down) { root.move(win.perRow); e.accepted = true }
                else if (e.key === Qt.Key_Up) { root.move(-win.perRow); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.confirm(); e.accepted = true }
                else if (e.key === Qt.Key_Escape) { root.cancel(); e.accepted = true }
                else if (root.sticky && e.text && e.text.length === 1 && e.text >= " ") { search.forceActiveFocus(); search.text += e.text; root.query = search.text; e.accepted = true }
            }
            Keys.onReleased: e => { if (!root.sticky && (e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr)) root.confirm() }
            Connections { target: root; function onVisibleChanged() { if (root.visible) frame.forceActiveFocus() } }

            TextField {   // Super+Tab: type to filter
                id: search
                visible: root.sticky
                x: 24; y: 20; width: parent.width - 48; height: 40
                text: root.query; onTextEdited: root.query = text
                placeholderText: "Type to find a window…"; placeholderTextColor: Theme.muted
                color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 38
                background: Rectangle { radius: 2; color: Theme.bgAlt; border.width: search.activeFocus ? 2 : 1; border.color: search.activeFocus ? Theme.blue : Theme.line }
                Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: Theme.muted; font.pixelSize: 14 }
                Keys.onReturnPressed: root.confirm()
                Keys.onEscapePressed: root.cancel()
                Keys.onTabPressed: root.move(1)
            }

            Grid {
                id: grid
                x: 24; y: root.sticky ? 76 : 24
                columns: win.perRow; spacing: 14
                Repeater {
                    model: root.visible ? root.shown.slice(0, 15) : []
                    Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === root.sel
                        width: 300; height: 220; radius: 2
                        color: selected ? Qt.rgba(0.88, 0.88, 0.88, 0.16) : (cm.containsMouse ? "#1eeaeaea" : Theme.card)
                        border.width: selected ? 2 : 1; border.color: selected ? Theme.blue : "#14eaeaea"
                        Behavior on color { ColorAnimation { duration: 90 } }

                        ClippingRectangle {   // live preview of the window
                            x: 10; y: 10; width: parent.width - 20; height: 160; radius: 2; color: Theme.bgAlt
                            ScreencopyView {
                                id: shot
                                anchors.centerIn: parent
                                captureSource: root.toplevelFor(card.modelData.address)
                                live: card.selected
                                constraintSize: Qt.size(parent.width, parent.height)
                            }
                            IconImage {   // shown until the preview arrives
                                anchors.centerIn: parent; visible: !shot.hasContent
                                implicitSize: 56; source: root.iconFor(card.modelData.cls); opacity: 0.8
                            }
                        }
                        Row {
                            x: 12; y: 182; spacing: 10; width: parent.width - 24
                            IconImage { id: ic; implicitSize: 24; source: root.iconFor(card.modelData.cls); anchors.verticalCenter: parent.verticalCenter }
                            Label {
                                width: parent.width - ic.width - wsTag.width - 20; anchors.verticalCenter: parent.verticalCenter
                                text: card.modelData.title; elide: Text.ElideRight
                                color: card.selected ? Theme.fg : Theme.fgDim; font.pixelSize: 12
                            }
                            Rectangle {
                                id: wsTag
                                anchors.verticalCenter: parent.verticalCenter
                                width: wsl.implicitWidth + 14; height: 20; radius: 2
                                color: card.selected ? Theme.blue : Theme.bgAlt
                                Label { id: wsl; anchors.centerIn: parent; text: card.modelData.wsName === "side" ? "side" : String(card.modelData.ws)
                                        color: card.selected ? Theme.bg : Theme.muted; font.pixelSize: 10 }
                            }
                        }
                        MouseArea {
                            id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.sel = card.index; root.confirm() }
                        }
                    }
                }
            }
            Label {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 12; anchors.horizontalCenter: parent.horizontalCenter
                visible: root.sticky
                text: "←→↑↓ choose · Enter switch · Esc close"; color: Theme.muted; font.pixelSize: 10
            }
        }
    }
}
