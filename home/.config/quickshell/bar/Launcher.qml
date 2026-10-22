import QtQuick
import Quickshell
Pill {
    padding: 10
    Label { text: "\u{f0765}"; color: Theme.fg; font.pixelSize: 15 }
    onClicked: m => Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", m.button === Qt.RightButton ? "alttab" : "launcher", m.button === Qt.RightButton ? "overview" : "toggle"])
}
