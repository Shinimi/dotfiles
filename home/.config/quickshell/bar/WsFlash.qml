// Workspace flash: when you switch workspace on the main screen, its kanji (一 二 三 …) fades through the
// middle of the screen for half a second. Click-through; off in Settings → Extras or during game mode. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: w
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsbar-wsflash"
    color: "transparent"
    mask: Region {}
    visible: anim.running
    readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    property bool armed: false
    Timer { running: true; interval: 2500; onTriggered: w.armed = true }
    onWsIdChanged: {
        if (!armed || wsId < 1 || !Settings.cur("ws_flash") || SysState.gameMode) return
        if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name !== modelData.name) return
        shownId = wsId; anim.restart()
    }
    property int shownId: 1

    Column {
        id: mark
        anchors.centerIn: parent; spacing: 6
        opacity: 0; scale: 0.94
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Theme.wsName(w.shownId)
            color: "#ffffff"; font.family: "Noto Serif CJK JP"; font.pixelSize: 230; font.weight: Font.Light
            style: Text.Raised; styleColor: "#66000000"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "WORKSPACE  " + String(w.shownId).padStart(2, "0")
            color: "#ffffff"; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 5
        }
    }
    SequentialAnimation {
        id: anim
        ParallelAnimation {
            NumberAnimation { target: mark; property: "opacity"; from: 0; to: 0.42; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: mark; property: "scale"; from: 0.94; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 160 }
        NumberAnimation { target: mark; property: "opacity"; to: 0; duration: 320; easing.type: Easing.InCubic }
    }
}
