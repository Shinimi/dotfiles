// Shows only when updates are waiting; click opens a terminal that updates. Made by Claude.
import QtQuick
import Quickshell

Pill {
    visible: Updates.total > 0
    padding: 10
    Label { text: "  " + Updates.total; color: Theme.blue }
    onClicked: {
        Quickshell.execDetached(["kitty", "--class", "updater", "-e", Quickshell.env("HOME") + "/.local/bin/safe-update.sh"])
        recheck.start()
    }
    Timer { id: recheck; interval: 120000; onTriggered: Updates.check() }
}
