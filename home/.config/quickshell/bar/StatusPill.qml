// Control center button: one icon, plus a small dot for notifications/updates. Scroll = volume. Made by Claude.
import QtQuick
import Quickshell.Services.Pipewire

Pill {
    id: pill
    property alias popup: cc
    padding: 11
    active: cc.visible
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Item {
        width: 16; height: 16
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Label { anchors.centerIn: parent; text: ""; color: Theme.fg; font.pixelSize: 14 }
        Rectangle {
            visible: (Notifs.count > 0 && !Notifs.dnd) || Updates.total > 0
            width: 7; height: 7; radius: 4
            color: Notifs.count > 0 && !Notifs.dnd ? Theme.red : Theme.blue
            x: parent.width - 2; y: -2
        }
    }
    onClicked: m => { if (m.button === Qt.RightButton && sink) sink.audio.muted = !sink.audio.muted; else cc.toggle() }
    onScrolled: d => { if (sink) sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.03 : -0.03))) }
    ControlCenter { id: cc; anchorItem: pill }
}
