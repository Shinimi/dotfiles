// ASCII living wallpaper (Settings → Extras): each screen's wallpaper redrawn as glowing characters,
// with a slow wave of light and rising motes. Sits on the desktop layer, behind windows. Updates at a
// calm 10 fps and stops completely in game mode. While it's on, hyprpaper isn't needed (it would only draw
// underneath), so it's stopped, and started again when you turn this off. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    readonly property bool on: Settings.cur("ascii_wall") === true
    Process { id: paper }
    function syncPaper() {
        paper.command = ["sh", "-c", on ? "pkill -x hyprpaper; true" : "pgrep -x hyprpaper >/dev/null || setsid -f hyprpaper >/dev/null 2>&1"]
        paper.running = true
    }
    onOnChanged: syncPaper()
    Component.onCompleted: syncPaper()
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
