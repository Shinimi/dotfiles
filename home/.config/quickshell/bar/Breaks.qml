// Break reminder: after 50 minutes at the PC without a real pause, one quiet nudge to stand up and rest your
// eyes. Being away for 5+ minutes counts as a break and starts the count again. Never while a game runs.
// Toggle: control center → Breaks. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root
    readonly property bool enabled: Settings.cur("break_reminder") === true
    readonly property int every: 50 * 60
    property int active: 0                         // seconds at the PC since the last break
    readonly property int left: Math.max(0, every - active)

    IdleMonitor { id: idle; enabled: root.enabled; timeout: 300; respectInhibitors: false
                  onIsIdleChanged: if (isIdle) root.active = 0 }
    onEnabledChanged: active = 0

    Timer {
        interval: 10000; running: root.enabled; repeat: true
        onTriggered: {
            if (idle.isIdle || SysState.gameMode) return
            root.active += 10
            if (root.active >= root.every) {
                root.active = 0
                Quickshell.execDetached(["notify-send", "-a", "Breaks", "-i", "preferences-desktop-accessibility",
                                         "Time for a short break", "50 minutes in. Stand up, stretch, and look at something far away for a minute."])
            }
        }
    }
}
