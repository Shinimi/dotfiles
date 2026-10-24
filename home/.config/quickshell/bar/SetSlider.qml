// Settings row with a slider: label and value on one line, the slider under it. Made by Claude.
import QtQuick
import QtQuick.Layouts

Item {
    id: r
    property string label; property string key; property real from: 0; property real to: 100; property real step: 1; property string suffix: ""
    property int decimals: 0
    readonly property real value: Settings.get(key)
    width: parent ? parent.width : 300; implicitHeight: inner.implicitHeight
    SetRowLine { show: r.Positioner.index > 0 }
    Column {
        id: inner
        width: parent.width; spacing: 8
        RowLayout {
            width: parent.width
            Label { text: r.label; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle {
                width: vt.implicitWidth + 14; height: 20; radius: 10; color: "#1d1d1d"
                Label { id: vt; anchors.centerIn: parent; text: r.value.toFixed(r.decimals) + r.suffix; color: "#c8c8c8"; font.family: Theme.font; font.pixelSize: 10 }
            }
        }
        Slider {
            accent: "#ececec"
            value: (r.value - r.from) / (r.to - r.from)
            onMoved: v => {
                const raw = r.from + v * (r.to - r.from)
                const snapped = Math.round(raw / r.step) * r.step
                Settings.set(r.key, Number(snapped.toFixed(2)))
            }
        }
    }
}
