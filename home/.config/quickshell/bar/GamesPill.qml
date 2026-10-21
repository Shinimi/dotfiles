// Opens the game library. Made by Claude.
import QtQuick
import Quickshell
Pill {
    padding: 10
    Label { text: ""; color: Theme.purple; font.pixelSize: 14 }
    onClicked: Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "games", "toggle"])
}
