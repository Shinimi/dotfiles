// Audio device row with volume (Settings → Sound). Made by Claude.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: r
    property var node; property bool current: false; property color accent: Theme.blue
    signal picked()
    readonly property string nice: {
        const n = node ? (node.nickname || node.description || node.name || "") : ""
        return n.replace(/ Analog Stereo| Digital Stereo \(HDMI\)| Mono| Stereo/g, "").slice(0, 34)
    }
    width: parent ? parent.width : 300; height: current ? 72 : 44; radius: 12
    color: current ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : (m.containsMouse ? Theme.bgHover : "#33111111")
    border.width: current ? 1 : 0; border.color: accent
    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!r.current) r.picked() }
    Column {
        x: 12; y: 12; width: parent.width - 24; spacing: 10
        RowLayout {
            width: parent.width
            Rectangle { width: 10; height: 10; radius: 5; color: r.current ? r.accent : "transparent"; border.width: 2; border.color: r.current ? r.accent : Theme.line }
            Label { text: r.nice; color: r.current ? Theme.fg : Theme.fgDim; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
            Label { visible: r.current && r.node && r.node.audio; text: r.node && r.node.audio ? Math.round(r.node.audio.volume * 100) + "%" : ""; color: r.accent; font.pixelSize: 11 }
        }
        Slider {
            visible: r.current && r.node && r.node.audio
            accent: r.accent
            value: r.node && r.node.audio ? Math.min(1, r.node.audio.volume) : 0
            onMoved: v => { if (r.node && r.node.audio) { r.node.audio.muted = false; r.node.audio.volume = v } }
        }
    }
}
