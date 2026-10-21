// System panel: CPU + GPU cards, then memory. Made by Claude.
import QtQuick
import QtQuick.Layouts

BarPopup {
    contentWidth: 320
    RowLayout {
        width: parent.width
        Label { text: "System"; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
        Label { text: "  up " + Stats.d.uptime; color: Theme.muted; font.pixelSize: 11 }
    }
    RowLayout {
        width: parent.width; spacing: 10
        StatCard {
            Layout.fillWidth: true; Layout.preferredWidth: 1
            icon: ""; title: "CPU"; accent: Theme.cyan
            usage: Stats.d.cpu; temp: Stats.d.cpuTemp
            extraIcon: ""; extra: Stats.d.cpuFreq + " GHz"
        }
        StatCard {
            Layout.fillWidth: true; Layout.preferredWidth: 1
            icon: "\u{f08ae}"; title: "GPU"; accent: Theme.purple
            usage: Stats.d.gpu; temp: Stats.d.gpuTemp
            extraIcon: ""; extra: Stats.d.gpuPower + " W"
        }
    }
    Meter { icon: ""; label: "Memory"; value: Stats.d.ramUsed.toFixed(1) + " / " + Stats.d.ramTotal.toFixed(0) + " GB"; fraction: Stats.d.ram / 100; accent: Theme.yellow }
    Meter { icon: "\u{f035b}"; label: "Video memory"; value: Stats.d.vramUsed.toFixed(1) + " / " + Stats.d.vramTotal.toFixed(0) + " GB"; fraction: Stats.d.vramUsed / Math.max(1, Stats.d.vramTotal); accent: Theme.green }
}
