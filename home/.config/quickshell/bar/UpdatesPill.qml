// Shows only when updates are waiting; click opens a terminal that updates. Made by Claude.
import QtQuick
import Quickshell

Pill {
    visible: Updates.total > 0
    padding: 10
    Label { text: "  " + Updates.total; color: Theme.blue }
    onClicked: {
        Quickshell.execDetached(["kitty", "--class", "updater", "-e", "bash", "-c",
            "echo 'Updating system (repo: " + Updates.repo + ", AUR: " + Updates.aur + ")'; yay -Syu; echo; read -n1 -rsp 'Done – press any key to close'"])
        recheck.start()
    }
    Timer { id: recheck; interval: 120000; onTriggered: Updates.check() }
}
