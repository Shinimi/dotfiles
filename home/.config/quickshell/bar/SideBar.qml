// The side screen's bar: just its four workspaces as floating dots, top left, like the main bar. Click or scroll to switch. Made by Claude.
import QtQuick
import Quickshell

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barBottom
    visible: !PopupState.focusMode
    exclusiveZone: PopupState.focusMode ? 0 : Theme.barBottom
    color: "transparent"
    mask: Region { item: strip }

    Rectangle {
        id: strip
        x: Settings.cur("gaps_out"); y: Theme.barTop
        width: ws.implicitWidth + 12; height: Theme.barHeight
        color: "transparent"   // floating, like the main bar: just the dots
        Loader {   // Hyprland's workspace dots, or Niri's
            id: ws; anchors.centerIn: parent
            sourceComponent: Niri.active ? niriDots : hyprDots
            Component { id: hyprDots; Workspaces { screenName: "DP-2"; dots: true } }
            Component { id: niriDots; NiriWorkspaces { screenName: "DP-2" } }
        }
    }
}
