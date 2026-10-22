import QtQuick
import Quickshell
Pill {
    padding: 10
    Label { text: "\u{f1589}"; color: Theme.purple; font.pixelSize: 17 }   // butterfly
    onClicked: m => Quickshell.execDetached(m.button === Qt.RightButton ? [Quickshell.env("HOME") + "/.local/bin/launcher.sh", "window"] : [Quickshell.env("HOME") + "/.local/bin/launcher.sh", "drun"])
}
