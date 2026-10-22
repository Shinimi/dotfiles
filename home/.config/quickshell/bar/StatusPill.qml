// Control center button: the sliders icon (a small dot for unread notifications).
// Click = control center, scroll = volume, right-click = mute. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Pill {
    id: pill
    padding: 11
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Item {
        width: 16; height: 16
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Label { anchors.centerIn: parent; text: ""; color: Theme.fg; font.pixelSize: 14 }
        Rectangle {
            visible: Notifs.count > 0 && !Notifs.dnd
            width: 6; height: 6; radius: 3
            color: "#ffffff"
            x: parent.width - 2; y: -2
        }
    }
    onClicked: m => { if (m.button === Qt.RightButton && sink) sink.audio.muted = !sink.audio.muted
                     else Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.env("HOME") + "/.config/quickshell/bar", "call", "panel", "toggle"]) }
    onScrolled: d => { if (sink) sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.03 : -0.03))) }
}
