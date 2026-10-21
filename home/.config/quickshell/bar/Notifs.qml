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
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return
            root.removePopup(n.id)                       // replaced notification: show it fresh
            root.popups.insert(0, { nid: n.id })
            while (root.popups.count > 4) root.popups.remove(root.popups.count - 1)
        }
    }
}
