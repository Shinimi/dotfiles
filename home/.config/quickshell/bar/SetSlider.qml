// Settings row with a slider. Made by Claude.
import QtQuick
import QtQuick.Layouts

Column {
    id: r
    property string label; property string key; property real from: 0; property real to: 100; property real step: 1; property string suffix: ""
    property int decimals: 0
    readonly property real value: Settings.get(key)
    width: parent ? parent.width : 300; spacing: 6
    RowLayout {
        width: parent.width
        Label { text: r.label; color: Theme.fgDim; font.pixelSize: 12; Layout.fillWidth: true }
        Label { text: r.value.toFixed(r.decimals) + r.suffix; color: Theme.blue; font.pixelSize: 12 }
    }
    Slider {
        accent: Theme.blue
        value: (r.value - r.from) / (r.to - r.from)
        onMoved: v => {
            const raw = r.from + v * (r.to - r.from)
            const snapped = Math.round(raw / r.step) * r.step
            Settings.set(r.key, Number(snapped.toFixed(2)))
        }
    }
}
