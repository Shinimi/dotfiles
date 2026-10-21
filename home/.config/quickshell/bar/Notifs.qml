// Notification server (replaces swaync). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    property var popups: []
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    function removePopup(n) { popups = popups.filter(p => p !== n) }
    function clearAll() { const all = list.slice(); popups = []; Qt.callLater(() => { for (const n of all) n.dismiss() }) }

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
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups).slice(0, 4)
        }
    }
}
