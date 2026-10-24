// Main-screen workspaces: 1-4 always, plus any higher one that is active or has windows.
// Small tiles like tiny windows: white = current, outlined = has windows, plain number = empty, a pulsing
// outline = a window there wants attention. Scroll over them to switch. Hover one you're not on and a small live
// preview of its windows drops down (Settings → Extras). Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Pill {
    id: wsPill
    padding: 4
    color: "transparent"
    onScrolled: d => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"e" + (d > 0 ? "-1" : "+1") + "\" })"])   // scroll to switch
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
    // which app is on each workspace (from Hyprland's own window list, refreshed on window events)
    property var wsApp: ({})
    property var wsOfAddr: ({})       // window address -> workspace (for "this window wants attention")
    property var urgentWs: ({})
    Process {
        id: appsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const m = {}, a = {}
                for (const c of JSON.parse(this.text)) {
                    if (c.workspace) a[String(c.address).replace(/^0x/, "")] = c.workspace.id
                    if (c.mapped !== false && c.workspace && !(c.workspace.id in m) && c.class) m[c.workspace.id] = c.class
                }
                wsPill.wsApp = m; wsPill.wsOfAddr = a
            } catch (e) {}
        } }
    }
    Timer { id: appsLater; interval: 250; onTriggered: if (!appsProc.running) appsProc.running = true }
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "urgent") {   // data = window address
                const ws = wsPill.wsOfAddr[String(e.data).replace(/^0x/, "")]
                if (ws) { const u = Object.assign({}, wsPill.urgentWs); u[ws] = true; wsPill.urgentWs = u }
            } else if (e.name === "workspace" || e.name === "workspacev2") {   // going there clears it
                const id = parseInt(String(e.data).split(",")[0]); if (wsPill.urgentWs[id]) { const u = Object.assign({}, wsPill.urgentWs); delete u[id]; wsPill.urgentWs = u }
            }
            if (/^(openwindow|closewindow|movewindow|windowtitle|workspace|activewindow)/.test(e.name)) appsLater.restart()
        }
    }
    Component.onCompleted: appsLater.restart()
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
            anchors.fill: parent; anchors.margins: 4; radius: 16
            color: "#f50b0b0b"; border.width: 1; border.color: "#1fffffff"
            Row {
                x: 12; y: 9; spacing: 8
                Text { text: String(wsPill.previewWs).padStart(2, "0"); color: "#7a7a7a"; font.family: Theme.font; font.pixelSize: 10 }
                Text { text: "//"; color: "#454545"; font.family: Theme.font; font.pixelSize: 10 }
                Text { text: Theme.wsName(wsPill.previewWs); color: "#f0f0f0"; font.family: Theme.font; font.pixelSize: 11 }
                Text { text: prev.wins.length + (prev.wins.length === 1 ? " window" : " windows"); color: "#7a7a7a"
                       font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {   // the screen in miniature
                id: mini
                x: 12; y: 30; width: 336 - 8; height: 1440 * prev.k - 4; color: "#0a0a0a"; clip: true; radius: 8
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
                Text { anchors.centerIn: parent; visible: prev.wins.length === 0; text: "Empty"; color: "#4a4a4a"; font.family: Theme.font; font.pixelSize: 11 }
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
            id: chip
            required property var modelData
            readonly property int wsId: modelData
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            readonly property bool isActive: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)
                                             || !!(ws && ws.monitor && ws.monitor.name === "DP-1" && ws.monitor.activeWorkspace === ws)
            readonly property bool hasWindows: !!(ws && ws.toplevels && ws.toplevels.values.length > 0)
            // the app on it: its icon stands for the workspace (games show Steam's)
            readonly property string app: hasWindows ? (wsPill.wsApp[wsId] || "") : ""
            readonly property string ico: {
                if (!app) return ""
                if (/^steam_app_\d+$|^gamescope$/.test(app)) return Quickshell.iconPath("steam", true)
                const e = DesktopEntries.heuristicLookup(app)
                return Quickshell.iconPath(e && e.icon ? e.icon : app.toLowerCase(), true) || ""
            }
            readonly property bool urgent: !!wsPill.urgentWs[wsId] && !isActive
            // a small tile per workspace, like a tiny window: white = you're here, outlined = has windows,
            // just the number = empty, a pulsing outline = a window there wants you
            width: 24; height: 22; radius: Math.max(4, Settings.cur("rounding") - 2)
            color: isActive ? "#f2f2f2" : wsMouse.containsMouse ? "#22ffffff" : "transparent"
            border.width: isActive ? 0 : (hasWindows || urgent) ? 1 : 0
            border.color: urgent ? "#ffffff" : "#4a4a4a"
            Behavior on color { ColorAnimation { duration: 150 } }
            SequentialAnimation on border.color {
                running: chip.urgent; loops: Animation.Infinite
                ColorAnimation { to: "#ffffff"; duration: 500 } ColorAnimation { to: "#3a3a3a"; duration: 500 }
            }
            Text {
                anchors.centerIn: parent
                text: Theme.wsName(chip.wsId); font.family: Theme.font; font.pixelSize: 11; font.bold: chip.isActive || chip.hasWindows
                color: chip.isActive ? "#0c0c0c" : wsMouse.containsMouse || chip.urgent ? "#ffffff" : chip.hasWindows ? "#cfcfcf" : "#4e4e4e"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: wsMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onEntered: wsPill.hoverWs(chip.wsId, parent, chip.isActive)
                onExited: wsPill.leaveWs()
                onClicked: { wsPill.leaveWs(); Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + chip.wsId + " })"]) }
            }
        }
    }
}
