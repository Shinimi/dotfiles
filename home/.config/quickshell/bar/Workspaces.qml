// Main-screen workspaces: 1-4 always, plus any higher one that is active or has windows.
// Dots: faint = empty, grey = has windows; the one you're on is a white pill with its kanji. Hover one you're not on and a small live
// preview of its windows drops down (Settings → Extras). Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Pill {
    id: wsPill
    padding: 4
    // ---- hover preview ----
    property int pendingWs: 0
    property Item pendingItem: null
    property int previewWs: 0
    property Item previewItem: null
    property var clients: []
    Timer { id: hoverIn; interval: 380; onTriggered: { wsPill.previewItem = wsPill.pendingItem; wsPill.previewWs = wsPill.pendingWs; cl.running = true } }
    Timer { id: hoverOut; interval: 160; onTriggered: wsPill.previewWs = 0 }
    function hoverWs(id, item, active) {
        if (!Settings.cur("ws_preview") || active) { hoverIn.stop(); previewWs = 0; return }
        pendingWs = id; pendingItem = item; hoverOut.stop(); hoverIn.restart()
    }
    function leaveWs() { hoverIn.stop(); hoverOut.restart() }
    Process { id: cl; command: ["hyprctl", "clients", "-j"]
              stdout: StdioCollector { onStreamFinished: { try { wsPill.clients = JSON.parse(this.text).filter(c => c.mapped !== false) } catch (e) {} } } }
    function toplevelFor(addr) {
        const a = addr.replace(/^0x/, "").toLowerCase()
        for (const t of Hyprland.toplevels.values) if (String(t.address).replace(/^0x/, "").toLowerCase() === a) return t.wayland
        return null
    }
    PopupWindow {
        id: prev
        visible: wsPill.previewWs > 0 && wsPill.previewItem !== null
        anchor.item: wsPill.previewItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 12
        implicitWidth: 360; implicitHeight: 238
        color: "transparent"
        readonly property var wins: wsPill.clients.filter(c => c.workspace.id === wsPill.previewWs && c.monitor === 0)
        readonly property real k: 336 / 2560
        Rectangle {
            anchors.fill: parent; anchors.margins: 4; radius: 2
            color: Theme.mix(Qt.rgba(0.03, 0.03, 0.03, 0.95), Theme.tint, 0.07 * Theme.tintOn); border.width: 1; border.color: "#3dffffff"
            Row {
                x: 12; y: 9; spacing: 8
                Text { text: String(wsPill.previewWs).padStart(2, "0"); color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 10 }
                Text { text: Theme.wsName(wsPill.previewWs); color: "#f0f0f0"; font.family: "Noto Sans CJK JP"; font.pixelSize: 11 }
                Text { text: prev.wins.length + (prev.wins.length === 1 ? " WINDOW" : " WINDOWS"); color: "#7a7a7a"
                       font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {   // the screen in miniature
                id: mini
                x: 12; y: 30; width: 336 - 8; height: 1440 * prev.k - 4; color: "#0a0a0a"; clip: true
                border.width: 1; border.color: "#1affffff"
                Repeater {
                    model: prev.wins
                    Rectangle {
                        required property var modelData
                        x: modelData.at[0] * prev.k; y: modelData.at[1] * prev.k
                        width: Math.max(16, modelData.size[0] * prev.k); height: Math.max(12, modelData.size[1] * prev.k)
                        color: "#161616"; border.width: 1; border.color: "#40ffffff"; clip: true
                        ScreencopyView { anchors.fill: parent; anchors.margins: 1; captureSource: wsPill.previewWs > 0 ? wsPill.toplevelFor(modelData.address) : null; live: false }
                    }
                }
                Text { anchors.centerIn: parent; visible: prev.wins.length === 0; text: "empty"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11 }
            }
        }
    }
    readonly property var extra: Hyprland.workspaces.values
        .filter(w => w.id > 4 && w.monitor && w.monitor.name === "DP-1"
                     && ((w.toplevels && w.toplevels.values.length > 0) || (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === w.id)))
        .map(w => w.id)
    readonly property var allIds: [1, 2, 3, 4].concat(extra.filter((v, i, a) => a.indexOf(v) === i).sort((a, b) => a - b))
    property int part: 0                 // 0 = all, 1 = first half, 2 = second half (the bar splits them around the clock)
    readonly property var ids: part === 0 ? allIds : part === 1 ? allIds.slice(0, Math.ceil(allIds.length / 2)) : allIds.slice(Math.ceil(allIds.length / 2))

    Repeater {
        model: ids
        Rectangle {
            required property var modelData
            readonly property int wsId: modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            readonly property bool isActive: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)
                                             || !!(ws && ws.monitor && ws.monitor.name === "DP-1" && ws.monitor.activeWorkspace === ws)
            readonly property bool hasWindows: !!(ws && ws.toplevels && ws.toplevels.values.length > 0)
            // dots: faint = empty, grey = has windows, a white pill with its kanji = the one you're on
            width: isActive ? 40 : 18; height: 24
            color: "transparent"
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: isActive ? 34 : (wsMouse.containsMouse ? 10 : 7); height: isActive ? 18 : width; radius: height / 2
                color: isActive ? "#f2f2f2" : wsMouse.containsMouse ? "#d0d0d0" : (hasWindows ? "#8a8a8a" : "#3a3a3a")
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }
                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    opacity: isActive ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 160 } }
                    text: Theme.wsName(wsId); color: "#0c0c0c"; font.bold: true
                    font.family: Theme.font; font.pixelSize: 10
                }
            }
            MouseArea {
                id: wsMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onEntered: wsPill.hoverWs(wsId, parent, isActive)
                onExited: wsPill.leaveWs()
                onClicked: { wsPill.leaveWs(); Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"]) }
            }
        }
    }
}
