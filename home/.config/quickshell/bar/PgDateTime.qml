// Settings → Date & time: clock, time zone and sync. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property var td: ({})
    SystemClock { id: clk; precision: SystemClock.Seconds }
    Process {
        id: load; running: pg.visible
        command: ["timedatectl", "show"]
        stdout: StdioCollector { onStreamFinished: { const o = {}; for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) } pg.td = o } }
    }
    Timer { id: again; interval: 1500; onTriggered: load.running = true }
    Rectangle {
        width: parent.width; height: 140; radius: 2; color: Theme.card; border.width: 1; border.color: "#14eaeaea"
        Column {
            anchors.centerIn: parent; spacing: 4
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clk.date, Settings.get("clock_12h") ? "h:mm:ss AP" : "HH:mm:ss"); font.pixelSize: 44; font.weight: Font.Bold }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clk.date, "dddd, d MMMM yyyy"); color: Theme.blue; font.pixelSize: 13 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: (pg.td.Timezone || "") + (pg.td.NTPSynchronized === "yes" ? "  ·  \u{f012c} in sync" : ""); color: Theme.muted; font.pixelSize: 11 }
        }
    }
    Row {
        width: parent.width; spacing: 14
        SetSection {
            width: (parent.width - 14) / 2; title: "Clock"; icon: "\u{f0954}"
            SetToggle { label: "12-hour clock"; key: "clock_12h" }
            SetToggle { label: "Show seconds in the bar"; key: "clock_seconds" }
            SetSwitch { label: "Set time automatically"; desc: "sync with internet time servers (instant)"; on: pg.td.NTP === "yes"
                onToggled: { Quickshell.execDetached(["timedatectl", "set-ntp", pg.td.NTP === "yes" ? "false" : "true"]); again.restart() } }
        }
    }
}
