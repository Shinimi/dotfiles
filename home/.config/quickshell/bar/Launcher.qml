import QtQuick
import Quickshell
Pill {
    implicitWidth: 34   // every icon button on the bar is the same square-ish size
    Label { text: "\uf303"; color: "#ffffff"; font.pixelSize: 15 }
    onClicked: m => Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", m.button === Qt.RightButton ? "alttab" : "launcher", m.button === Qt.RightButton ? "overview" : "toggle"])
}
