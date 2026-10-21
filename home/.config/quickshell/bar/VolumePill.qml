// Volume; scroll to change, click for the volume menu. Made by Claude.
import QtQuick
import Quickshell.Services.Pipewire

Pill {
    property alias popup: menu
    id: pill
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    active: menu.visible
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    Label {
        text: muted ? "" : (vol < 0.01 ? "" : vol < 0.5 ? "" : "")
        color: muted ? Theme.muted : Theme.green
    }
    Label { text: Math.round(vol * 100) + "%"; color: muted ? Theme.muted : Theme.fg }
    onClicked: m => {
        if (m.button === Qt.RightButton && sink) sink.audio.muted = !sink.audio.muted
        else menu.toggle()
    }
    onScrolled: d => { if (sink) sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.03 : -0.03))) }
    VolumePopup { id: menu; anchorItem: pill }
}
