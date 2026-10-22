// Invisible full-screen layer under rofi: clicking anywhere outside the launcher closes it. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: w
    required property var screen
    property bool on: false
    visible: on
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qsbar-dismiss"
    color: "#330d0c13"
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: { w.on = false; Quickshell.execDetached(["pkill", "-x", "rofi"]) } }
    IpcHandler { target: "shield"; function enable(): void { w.on = true } function disable(): void { w.on = false } }
}
