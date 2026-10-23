// Settings row with a slider. Made by Claude.
import QtQuick
import QtQuick.Layouts

Column {
    id: r
    property string label; property string key; property real from: 0; property real to: 100; property real step: 1; property string suffix: ""
    property int decimals: 0
    readonly property real value: Settings.get(key)
    width: parent ? parent.width : 300; spacing: 8
    RowLayout {
        width: parent.width
        Label { text: r.label; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true }
        Label { text: r.value.toFixed(r.decimals) + r.suffix; color: "#8a8a8a"; font.family: Theme.font; font.pixelSize: 11 }
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
