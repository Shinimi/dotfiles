// Screensaver: when you've been away a while (before the lock), the screen fades to black and
// your wallpaper is redrawn in glowing ASCII characters around a thin clock and today's line. Any key or mouse move wakes it.
// Started by hypridle (qs ipc call screensaver start|stop). On/off in Settings → Extras. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool on: false
    IpcHandler {
        target: "screensaver"
        function start(): void { if (Settings.cur("screensaver")) root.on = true }
        function stop(): void { root.on = false }
    }

    Variants {   // every screen
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            // at night the side screen belongs to the desk clock (DeskClock.qml)
            readonly property bool deskNight: modelData.name === "DP-2" && Settings.cur("desk_clock") !== false && (h => h >= 22 || h < 8)(new Date().getHours())
            visible: (root.on || fade.running) && !deskNight
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qsbar-screensaver"
            WlrLayershell.keyboardFocus: root.on && modelData.name === "DP-1" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            Rectangle {
                id: bg
                anchors.fill: parent; color: "#000000"
                opacity: root.on ? 1 : 0
                Behavior on opacity { NumberAnimation { id: fade; duration: 1600; easing.type: Easing.InOutQuad } }

                AsciiView {   // your wallpaper, drawn in glowing characters
                    anchors.fill: parent
                    source: Settings.cur(modelData.name === "DP-2" ? "wall_side" : "wall_main")
                    running: root.on
                }
                Rectangle {   // a dark band behind the clock so it always reads
                    anchors.centerIn: parent; width: parent.width; height: 480
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" } GradientStop { position: 0.25; color: "#ee000000" }
                        GradientStop { position: 0.75; color: "#ee000000" } GradientStop { position: 1.0; color: "#00000000" } }
                }

                Column {
                    anchors.centerIn: parent; spacing: 10
                    SystemClock { id: clk; precision: SystemClock.Minutes }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clk.date, Settings.cur("clock_12h") ? "h:mm" : "HH:mm")
                        font.family: Theme.font; font.pixelSize: 150; font.weight: Font.Thin; color: "#e8e8e8"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clk.date, "dddd, d MMMM").toLowerCase()
                        font.family: Theme.font; font.pixelSize: 20; font.letterSpacing: 3; color: "#8a8a8a"
                    }
                    Item { width: 1; height: 26 }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Journey.today()
                        font.family: Theme.font; font.pixelSize: 15; font.italic: true; font.letterSpacing: 1; color: "#9a9a9a"
                    }
                }

                MouseArea {   // wake on movement or a click (ignore the first tiny jitter)
                    anchors.fill: parent; hoverEnabled: true
                    property point start: Qt.point(-1, -1)
                    onPositionChanged: m => {
                        if (start.x < 0) { start = Qt.point(m.x, m.y); return }
                        if (Math.abs(m.x - start.x) + Math.abs(m.y - start.y) > 12) { root.on = false; start = Qt.point(-1, -1) }
                    }
                    onClicked: root.on = false
                }
                Item { anchors.fill: parent; focus: root.on; Keys.onPressed: root.on = false }
            }
        }
    }
}
