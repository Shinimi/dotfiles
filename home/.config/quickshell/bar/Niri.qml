// Niri's workspaces and windows for the bar, kept live from `niri msg event-stream` (no polling).
// Only runs in the Niri session; in Hyprland `active` is false and nothing starts. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: n
    readonly property bool active: (Quickshell.env("NIRI_SOCKET") || "") !== ""
    property var workspaces: []          // [{ id, idx, name, output, is_active, is_focused, is_urgent }]
    property var count: ({})             // workspace id -> how many windows it has
    property var wins: ({})              // window id -> workspace id (not a binding source: titles change a lot)
    function act(args) { Quickshell.execDetached(["niri", "msg", "action"].concat(args)) }
    // an action on a given screen (workspace numbers are per screen in Niri)
    function onScreen(screen, args) {
        Quickshell.execDetached(["sh", "-c", "niri msg action focus-monitor \"$1\"; shift; niri msg action \"$@\"", "sh", screen].concat(args))
    }
    function recount() {
        const c = {}
        for (const k in wins) c[wins[k]] = (c[wins[k]] || 0) + 1
        count = c
    }
    function handle(ev) {
        if (ev.WorkspacesChanged) workspaces = ev.WorkspacesChanged.workspaces
        else if (ev.WorkspaceActivated) {
            const a = ev.WorkspaceActivated, t = workspaces.find(w => w.id === a.id)
            if (!t) return
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === t.output ? w.id === a.id : w.is_active,
                is_focused: a.focused ? w.id === a.id : w.is_focused }))
        } else if (ev.WorkspaceUrgencyChanged) {
            const u = ev.WorkspaceUrgencyChanged
            workspaces = workspaces.map(w => w.id === u.id ? Object.assign({}, w, { is_urgent: u.urgent }) : w)
        } else if (ev.WindowsChanged) {
            const m = {}
            for (const w of ev.WindowsChanged.windows) m[w.id] = w.workspace_id
            wins = m; recount()
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window
            if (wins[w.id] !== w.workspace_id) { wins[w.id] = w.workspace_id; recount() }
        } else if (ev.WindowClosed) {
            if (ev.WindowClosed.id in wins) { delete wins[ev.WindowClosed.id]; recount() }
        }
    }
    Process {
        id: stream
        running: n.active
        command: ["niri", "msg", "-j", "event-stream"]
        stdout: SplitParser { onRead: line => { try { n.handle(JSON.parse(line)) } catch (e) {} } }
        onExited: if (n.active) again.start()          // Niri restarted the socket: reconnect
    }
    Timer { id: again; interval: 2000; onTriggered: stream.running = true }
}
