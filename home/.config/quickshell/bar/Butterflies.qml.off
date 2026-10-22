// Butterflies drifting over the wallpaper. They only fly when the workspace is empty (nothing to
// re-blur, no GPU cost behind windows) and never during game mode. Toggle: Settings → Effects. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: w
    required property var screen
    readonly property var ws: Hyprland.focusedWorkspace
    readonly property bool empty: !!ws && ws.monitor && ws.monitor.name === screen.name
                                  && (!ws.toplevels || ws.toplevels.values.length === 0)
    readonly property bool flying: Settings.cur("butterflies") && empty && !SysState.gameMode
    visible: Settings.cur("butterflies")
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qsbar-butterflies"
    color: "transparent"
    mask: Region {}                       // clicks go straight through
    property int count: Settings.cur("butterfly_count") || 7

    Repeater {
        model: w.count
        Image {
            id: bf
            required property int index
            source: Qt.resolvedUrl("butterfly.svg")
            readonly property real sc: 0.28 + (index % 4) * 0.12
            width: 120 * sc; height: 90 * sc; sourceSize.width: width * 2; sourceSize.height: height * 2
            opacity: w.flying ? 0.55 + (index % 3) * 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: 1200 } }
            property real lane: w.height * (0.12 + ((index * 41) % 70) / 100)
            property real bob: 0
            y: lane + bob
            x: -200
            rotation: (index % 2 ? -8 : 10)
            transform: Scale { id: flap; origin.x: bf.width / 2; xScale: 1 }
            NumberAnimation on x {
                running: w.flying; loops: Animation.Infinite
                from: -200 - bf.index * 260; to: w.width + 200
                duration: 26000 + (bf.index % 3) * 7000
            }
            SequentialAnimation on bob {
                running: w.flying; loops: Animation.Infinite
                NumberAnimation { to: -60; duration: 3000 + bf.index * 230; easing.type: Easing.InOutSine }
                NumberAnimation { to: 40; duration: 3000 + bf.index * 230; easing.type: Easing.InOutSine }
            }
            SequentialAnimation {
                running: w.flying; loops: Animation.Infinite
                NumberAnimation { target: flap; property: "xScale"; to: 0.3; duration: 240 + bf.index * 25; easing.type: Easing.InOutQuad }
                NumberAnimation { target: flap; property: "xScale"; to: 1; duration: 240 + bf.index * 25; easing.type: Easing.InOutQuad }
            }
        }
    }
}
