// Volume menu: output slider, device picker, mic slider. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

BarPopup {
    id: popup
    contentWidth: 300
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    PwObjectTracker { objects: popup.sinks }

    component IconButton: Rectangle {
        property string icon; property bool on: false; signal hit()
        width: 32; height: 32; radius: 9
        color: on ? Theme.red : (bMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
        Label { anchors.centerIn: parent; text: icon; color: on ? Theme.bg : Theme.fg }
        MouseArea { id: bMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    RowLayout {
        width: parent.width
        Label { text: "Sound"; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
        Label { text: sink ? Math.round(sink.audio.volume * 100) + "%" : ""; color: Theme.blue; font.pixelSize: 15; font.weight: Font.Bold }
    }

    RowLayout {
        width: parent.width; spacing: 10
        IconButton {
            icon: sink && sink.audio.muted ? "" : ""; on: sink ? sink.audio.muted : false
            onHit: if (sink) sink.audio.muted = !sink.audio.muted
        }
        Slider {
            Layout.fillWidth: true; accent: Theme.green
            value: sink ? sink.audio.volume : 0
            onMoved: v => { if (sink) { sink.audio.muted = false; sink.audio.volume = v } }
        }
    }

    Label { text: "Output"; color: Theme.muted; font.pixelSize: 11 }
    Column {
        width: parent.width; spacing: 4
        Repeater {
            model: popup.sinks
            Rectangle {
                required property var modelData
                readonly property bool current: popup.sink && popup.sink.id === modelData.id
                width: parent.width; height: 34; radius: 9
                color: current ? Theme.bgHover : (devMouse.containsMouse ? Theme.bgAlt : "transparent")
                border.width: current ? 1 : 0; border.color: Theme.line
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Label { text: current ? "" : ""; color: current ? Theme.blue : Theme.muted }
                    Label {
                        text: modelData.nickname || modelData.description || modelData.name
                        elide: Text.ElideRight; Layout.fillWidth: true
                        color: current ? Theme.fg : Theme.fgDim; font.weight: current ? Font.DemiBold : Font.Normal
                    }
                }
                MouseArea { id: devMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData }
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }
    Label { text: "Microphone"; color: Theme.muted; font.pixelSize: 11 }
    RowLayout {
        width: parent.width; spacing: 10
        IconButton {
            icon: source && source.audio.muted ? "" : ""; on: source ? source.audio.muted : false
            onHit: if (source) source.audio.muted = !source.audio.muted
        }
        Slider {
            Layout.fillWidth: true; accent: Theme.purple
            value: source ? source.audio.volume : 0
            onMoved: v => { if (source) source.audio.volume = v }
        }
    }

    Rectangle {
        width: parent.width; height: 30; radius: 9
        color: mixMouse.containsMouse ? Theme.bgHover : Theme.bgAlt
        Label { anchors.centerIn: parent; text: "  Advanced mixer"; color: Theme.fgDim; font.pixelSize: 11 }
        MouseArea { id: mixMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { popup.visible = false; Quickshell.execDetached(["pavucontrol"]) } }
    }
}
