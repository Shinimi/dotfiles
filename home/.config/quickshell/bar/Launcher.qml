import QtQuick
import Quickshell
Pill {
    padding: 10
    color: hovered ? "#8fb0ff" : Theme.blue
    border.color: Theme.blue
    Label { text: ""; color: Theme.bg; font.pixelSize: 15 }
    onClicked: m => Quickshell.execDetached(m.button === Qt.RightButton ? ["rofi", "-show", "window"] : ["rofi", "-show", "drun"])
}
