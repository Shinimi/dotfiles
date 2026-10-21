// System panel: CPU + GPU cards, then memory. Made by Claude.
import QtQuick
import QtQuick.Layouts

BarPopup {
    contentWidth: 320
    function speed(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        if (b >= 1024) return Math.round(b / 1024) + " KB/s"
        return b + " B/s"
    }
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
    Rectangle {
        width: parent.width; height: 44; radius: 12; color: Theme.bgAlt
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
            Label { text: "\u{f0318}"; color: Theme.blue }
            Label { text: Stats.d.iface || "Network"; color: Theme.fgDim; Layout.fillWidth: true }
            Label { text: "\uf063 " + speed(Stats.d.netRx || 0); color: Theme.green; font.pixelSize: 11 }
            Label { text: "\uf062 " + speed(Stats.d.netTx || 0); color: Theme.purple; font.pixelSize: 11 }
        }
    }
}
