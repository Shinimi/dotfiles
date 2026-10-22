// ASCII living wallpaper (Settings → Extras): each screen's wallpaper redrawn as glowing characters,
// with a slow wave of light and rising motes. Sits on the desktop layer, behind windows. Updates at a
// calm 20 fps and stops completely in game mode. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: w
            required property var modelData
            screen: modelData
            visible: Settings.cur("ascii_wall")
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "qsbar-asciiwall"
            color: "#000000"
            mask: Region {}
            AsciiView {
                anchors.fill: parent
                source: Settings.cur(w.modelData.name === "DP-2" ? "wall_side" : "wall_main")
                running: w.visible && !SysState.gameMode
            }
        }
    }
}
