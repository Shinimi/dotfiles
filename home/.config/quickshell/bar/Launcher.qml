import QtQuick
import Quickshell
Pill {
    padding: 10
    Label { text: ""; color: Theme.blue; font.pixelSize: 15 }
    onClicked: m => Quickshell.execDetached(m.button === Qt.RightButton ? ["rofi", "-show", "window"] : ["rofi", "-show", "drun"])
}
