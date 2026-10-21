// Volume pop-up at the bottom of the main screen when the volume changes. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root
    required property var screen
    readonly property var sink: Pipewire.defaultAudioSink
    property bool shown: false
    property bool armed: false          // don't pop up during startup
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Timer { running: true; interval: 3000; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }
    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { if (root.armed) { root.shown = true; hide.restart() } }
        function onMutedChanged() { if (root.armed) { root.shown = true; hide.restart() } }
    }

    PanelWindow {
        visible: root.shown
        screen: root.screen
        anchors.bottom: true
        margins.bottom: 90
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-osd"
        color: "transparent"
        implicitWidth: 300; implicitHeight: 52
        mask: Region {}
        Rectangle {
            anchors.fill: parent; radius: 16; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            readonly property real v: root.sink && root.sink.audio ? root.sink.audio.volume : 0
            readonly property bool m: root.sink && root.sink.audio ? root.sink.audio.muted : false
            Row {
                anchors.centerIn: parent; spacing: 14
                Label { text: parent.parent.m ? "" : ""; color: parent.parent.m ? Theme.muted : Theme.green; font.pixelSize: 16; width: 20 }
                Rectangle {
                    width: 190; height: 8; radius: 4; color: Theme.bgAlt; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: Math.max(height, parent.width * Math.min(1, parent.parent.parent.v)); height: parent.height; radius: 4
                        color: parent.parent.parent.m ? Theme.muted : Theme.green
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
                Label { text: Math.round(parent.parent.v * 100); width: 26; horizontalAlignment: Text.AlignRight }
            }
        }
    }
}
