// Notification server (replaces swaync). Made by Claude.
// Pop-ups are tracked by notification ID (never by object), because apps can close/replace a
// notification at any time and Quickshell then deletes the object.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    property var missed: []          // app names of notifications that arrived while silent (for the game summary)
    onDndChanged: { if (dnd) missed = []; else dndUntil = 0 }
    property double dndUntil: 0      // timed silence (control center → Notifications): ms timestamp, 0 = until turned off
    function silenceFor(min) { dnd = true; dndUntil = Date.now() + min * 60000 }
    function silenceUntilMorning() { const d = new Date(); if (d.getHours() >= 8) d.setDate(d.getDate() + 1); d.setHours(8, 0, 0, 0); dnd = true; dndUntil = d.getTime() }
    Timer { interval: 15000; running: root.dndUntil > 0; repeat: true; onTriggered: if (Date.now() >= root.dndUntil) root.dnd = false }
    function summary() {             // one line after a game: "4 notifications while you played"
        if (!missed.length) return
        const by = {}; for (const a of missed) by[a] = (by[a] || 0) + 1
        const body = Object.keys(by).map(a => by[a] > 1 ? a + " ×" + by[a] : a).join(", ")
        const n = missed.length; missed = []
        Quickshell.execDetached(["notify-send", "-a", "Game mode", "-i", "input-gaming",
                                 n + (n === 1 ? " notification" : " notifications") + " while you played", body])
    }
    readonly property var model: server.trackedNotifications      // crash-safe live list for the panel
    readonly property int count: server.trackedNotifications.values.length
    property ListModel popups: ListModel {}

    function notifById(id) { return server.trackedNotifications.values.find(n => n.id === id) || null }
    function removePopup(id) {
        for (let i = popups.count - 1; i >= 0; i--) if (popups.get(i).nid === id) popups.remove(i)
    }
    function prune() {
        const alive = server.trackedNotifications.values.map(n => n.id)
        for (let i = popups.count - 1; i >= 0; i--) if (alive.indexOf(popups.get(i).nid) < 0) popups.remove(i)
    }
    function clearAll() {
        popups.clear()
        const all = server.trackedNotifications.values.slice()
        Qt.callLater(() => { for (const n of all) if (n) n.dismiss() })
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() { Qt.callLater(root.prune) }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) {
                if (n.appName !== "Game mode") root.missed = root.missed.concat([n.appName || "app"])
                return
            }
            root.removePopup(n.id)                       // replaced notification: show it fresh
            root.popups.insert(0, { nid: n.id })
            if (Settings.cur("sounds") !== false && !n.hints["suppress-sound"])
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/kocho-sound.sh",
                    n.urgency === NotificationUrgency.Critical ? "dialog-warning" : "message-new-instant"])
            while (root.popups.count > 4) root.popups.remove(root.popups.count - 1)
        }
    }
}
