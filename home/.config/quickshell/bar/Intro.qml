// Login handoff: right after you log in, every screen starts on the same ASCII dunes as the login screen,
// then they brighten for a moment and dissolve into your real desktop. Once per login (a bar restart doesn't
// replay it). Off in Settings → Extras. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool playing: false
    readonly property string theme: "/usr/share/sddm/themes/mono-yu/assets/"
    Process {   // first start this login?
        running: true
        command: ["sh", "-c", "f=\"$XDG_RUNTIME_DIR/qs-intro-done\"; [ -e \"$f\" ] && echo no || { : > \"$f\"; echo yes; }"]
        stdout: StdioCollector { onStreamFinished: if (this.text.trim() === "yes" && Settings.cur("login_handoff")) root.playing = true }
    }
    IpcHandler { target: "intro"; function play(): void { root.playing = true } }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: w
            required property var modelData
            screen: modelData
            visible: root.playing
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qsbar-intro"
            color: "transparent"
            mask: Region {}

            Item {
                id: stage
                anchors.fill: parent
                Rectangle { anchors.fill: parent; color: "#000000" }
                AsciiView {
                    id: art
                    anchors.fill: parent
                    source: root.theme + (w.modelData.name === "DP-2" ? "background2.png" : "ascii-background.jpg")
                    running: root.playing
                }
                Rectangle {   // same shading as the login screen, so the hand-over is seamless
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: "#d0000000" } GradientStop { position: 0.36; color: "#a0000000" }
                        GradientStop { position: 0.55; color: "#18000000" } GradientStop { position: 1.0;  color: "#40000000" }
                    }
                }
            }
            SequentialAnimation {
                running: root.playing && art.ready          // wait for the picture, then hold it a beat
                PauseAnimation { duration: 700 }
                ParallelAnimation {
                    NumberAnimation { target: stage; property: "scale"; from: 1.0; to: 1.04; duration: 1300; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: stage; property: "opacity"; from: 1.0; to: 0.0; duration: 1300; easing.type: Easing.InOutCubic }
                }
                ScriptAction { script: { root.playing = false; stage.opacity = 1; stage.scale = 1 } }
            }
        }
    }
}
