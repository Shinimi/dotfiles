import QtQuick
import Quickshell
Pill {
    padding: 10
    Label { text: "\uf303"; color: "#ffffff"; font.pixelSize: 16 }
    onClicked: m => Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", m.button === Qt.RightButton ? "alttab" : "launcher", m.button === Qt.RightButton ? "overview" : "toggle"])
}
