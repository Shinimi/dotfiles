// One small status pill: volume, notifications, updates. Click = control center, scroll = volume. Made by Claude.
import QtQuick
import Quickshell.Services.Pipewire

Pill {
    id: pill
    property alias popup: cc
    padding: 12
    active: cc.visible
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Label {
        visible: Updates.total > 0
        text: " " + Updates.total; color: Theme.blue
    }
    Label {
        text: (muted ? "" : (vol < 0.01 ? "" : vol < 0.5 ? "" : "")) + "  " + Math.round(vol * 100) + "%"
        color: muted ? Theme.muted : Theme.fg
    }
    Item {
        width: 13; height: 16
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Label { anchors.centerIn: parent; text: Notifs.dnd ? "" : ""; color: Notifs.dnd ? Theme.muted : Theme.fg }
        Rectangle {
            visible: Notifs.count > 0 && !Notifs.dnd
            width: 7; height: 7; radius: 4; color: Theme.red
            x: parent.width - 3; y: -1
        }
    }
    Label { text: ""; color: Theme.blue }

    onClicked: m => { if (m.button === Qt.RightButton && sink) sink.audio.muted = !sink.audio.muted; else cc.toggle() }
    onScrolled: d => { if (sink) sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.03 : -0.03))) }
    ControlCenter { id: cc; anchorItem: pill }
}
