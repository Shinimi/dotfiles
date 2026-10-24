// Volume pop-up: a slim pill near the bottom of the main screen for a second when the volume or mute changes
// (keys, scrolling on the bar, anything). Icon by level, the device's name, a bar and the percentage. Also shows
// the mic going mute / live. Not while the control center is open (its own sliders show it). Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property bool micMuted: !!(source && source.audio && source.audio.muted)
    property string kind: "vol"            // vol | mic
    property bool shown: false
    property bool armed: false             // nothing while the shell starts
    Timer { running: true; interval: 3000; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1300; onTriggered: root.shown = false }
    function show(k) {
        if (!armed || PopupState.focusMode) return
        if (PopupState.current && PopupState.current.toString().indexOf("ControlPanel") >= 0 && PopupState.current.visible) return
        kind = k; shown = true; hide.restart()
    }
    onVolChanged: show("vol")
    onMutedChanged: show("vol")
    onMicMutedChanged: show("mic")
    readonly property string name: {
        if (sink && sink.name === "headset_eq") return "Fuxi-H3 · EQ"     // the EQ is a virtual device in front of the headset
        const n = sink ? (sink.nickname || sink.description || sink.name || "") : ""
        return n.replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Stereo/g, "") || "Sound"
    }
    readonly property string icon: kind === "mic" ? (micMuted ? "\u{f036d}" : "\u{f036c}")
                                 : muted || vol <= 0 ? "\u{f075f}" : vol < 0.34 ? "\u{f057f}" : vol < 0.67 ? "\u{f0580}" : "\u{f057e}"

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === "DP-1") || Quickshell.screens[0]
        visible: pill.opacity > 0.01
        anchors.bottom: true
        margins.bottom: 70
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-osd"
        color: "transparent"
        implicitWidth: 340; implicitHeight: 64
        mask: Region {}                     // never catches clicks
        Rectangle {
            id: pill
            anchors.fill: parent; radius: 32
            color: "#f00b0b0b"; border.width: 1; border.color: "#24ffffff"
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Rectangle {
                id: ic; x: 10; anchors.verticalCenter: parent.verticalCenter; width: 44; height: 44; radius: 22
                color: (root.kind === "mic" ? root.micMuted : root.muted) ? "#1f1f1f" : "#ececec"
                Text { anchors.centerIn: parent; text: root.icon; font.family: Theme.font; font.pixelSize: 20
                       color: (root.kind === "mic" ? root.micMuted : root.muted) ? "#9a9a9a" : "#0b0b0b" }
            }
            Column {
                anchors.left: ic.right; anchors.leftMargin: 14; anchors.right: pct.left; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Text { width: parent.width; elide: Text.ElideRight; color: "#bdbdbd"; font.family: Theme.font; font.pixelSize: 10
                       text: root.kind === "mic" ? "Microphone" : root.name }
                Rectangle {
                    visible: root.kind === "vol"
                    width: parent.width; height: 6; radius: 3; color: "#26ffffff"
                    Rectangle { height: parent.height; radius: 3; color: root.muted ? "#5a5a5a" : "#ececec"; width: parent.width * Math.min(1, root.vol)
                                Behavior on width { NumberAnimation { duration: 90 } } }
                }
                Text { visible: root.kind === "mic"; text: root.micMuted ? "Muted" : "Live"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
            }
            Text {
                id: pct
                anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
                visible: root.kind === "vol"
                text: root.muted ? "Off" : Math.round(root.vol * 100) + "%"; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 14; font.bold: true
            }
        }
    }
}
