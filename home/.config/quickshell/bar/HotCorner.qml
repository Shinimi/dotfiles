// Hot corner: push the mouse into the top-left corner to open the workspace overview. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var screen
    visible: Settings.cur("hot_corner")
    anchors { top: true; left: true }
    implicitWidth: 3; implicitHeight: 3
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsbar-hotcorner"
    color: "transparent"
    HoverHandler { onHoveredChanged: hovered ? dwell.restart() : dwell.stop() }
    Timer {   // a short dwell so flicking past the corner doesn't trigger it
        id: dwell; interval: 140
        onTriggered: Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "overview", "toggle"])
    }
}
