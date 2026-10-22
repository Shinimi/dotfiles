// Screensaver: when you've been away a while (before the lock), the screen fades to black and
// motes of mana drift upward around a thin clock and today's line. Any key or mouse move wakes it.
// Started by hypridle (qs ipc call screensaver start|stop). On/off in Settings → Extras. Made by Claude.
import QtQuick
import QtQuick.Particles
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
            visible: root.on || fade.running
            required property var modelData
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

                ParticleSystem { id: sys; running: root.on }
                ImageParticle {   // soft glowing motes
                    system: sys; source: "qrc:///particleresources/glowdot.png"
                    color: "#55ffffff"; colorVariation: 0.0; alpha: 0.6; alphaVariation: 0.4
                    entryEffect: ImageParticle.Fade
                }
                Emitter {
                    system: sys
                    anchors.bottom: parent.bottom; width: parent.width; height: 40
                    emitRate: 9; lifeSpan: 16000; lifeSpanVariation: 5000
                    size: 10; sizeVariation: 14; endSize: 4
                    velocity: AngleDirection { angle: 270; angleVariation: 14; magnitude: 70; magnitudeVariation: 40 }
                }
                Wander { system: sys; xVariance: 60; pace: 40 }   // gentle sideways sway

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
                        text: "— " + Journey.today()
                        font.family: Theme.font; font.pixelSize: 15; font.italic: true; font.letterSpacing: 1; color: "#5e5e5e"
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
