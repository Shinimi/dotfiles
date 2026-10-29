// Settings → Packages: your week in packages, leftovers and cache you can clear, and what takes the most space. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Column {
    id: pg
    spacing: 14
    property var d: ({ counts: { upgraded: 0, installed: 0, removed: 0 }, changes: [], biggest: [], orphans: [], aur: [], installed: 0, explicit: 0, totalBytes: 0, orphanBytes: 0, cacheBytes: 0 })
    property bool showAll: false
    function gb(b) { return b >= 1e9 ? (b / 1e9).toFixed(1) + " GB" : Math.round(b / 1e6) + " MB" }
    function term(cmd) { Quickshell.execDetached(["kitty", "--class", "floating-term", "-e", "sh", "-c", cmd + "; echo; read -p 'Done. Press Enter to close.' _"]); reload.restart() }
    Process {
        id: load; running: pg.visible
        command: ["python3", "-I", Qt.resolvedUrl("pkgwatch.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { pg.d = JSON.parse(this.text) } catch (e) {} } }
    }
    Timer { id: reload; interval: 15000; onTriggered: load.running = true }   // after a cleanup in the terminal

    Row {   // this week at a glance
        width: parent.width; spacing: 10
        Repeater {
            model: [[pg.d.counts.upgraded, "updated", "this week"], [pg.d.counts.installed, "added", "this week"], [pg.d.counts.removed, "removed", "this week"],
                    [pg.d.installed, "installed", pg.d.explicit + " picked by you"]]
            Rectangle {
                required property var modelData
                width: (pg.width - 30) / 4; height: 84; radius: 18; color: "#111111"; border.width: 1; border.color: "#1c1c1c"
                Column {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: modelData[0]; color: "#ffffff"; font.family: Theme.font; font.pixelSize: 26; font.bold: true }
                    Label { text: modelData[1]; font.pixelSize: 11 }
                    Label { text: modelData[2]; color: "#5a5a5a"; font.pixelSize: 9; font.weight: Font.Normal }
                }
            }
        }
    }

    SetSection {
        width: parent.width; title: "Clean up"; icon: "\u{f00e2}"
        RowLayout {
            width: parent.width; spacing: 12
            Column {
                Layout.fillWidth: true; spacing: 2
                Label { text: pg.d.orphans.length ? pg.d.orphans.length + " leftover packages · " + pg.gb(pg.d.orphanBytes) : "No leftover packages"; font.pixelSize: 12 }
                Label { width: parent.width; wrapMode: Text.WordWrap; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal
                        text: pg.d.orphans.length ? pg.d.orphans.slice(0, 8).join(", ") + (pg.d.orphans.length > 8 ? "…" : "") : "Installed as helpers for something you've since removed: none right now." }
            }
            SetButton { visible: pg.d.orphans.length > 0; icon: "\u{f0a7a}"; text: "Remove leftovers"; onClicked: pg.term("sudo pacman -Rns $(pacman -Qdtq)") }
        }
        RowLayout {
            width: parent.width; spacing: 12
            Column {
                Layout.fillWidth: true; spacing: 2
                Label { text: "Download cache · " + pg.gb(pg.d.cacheBytes); font.pixelSize: 12 }
                Label { width: parent.width; wrapMode: Text.WordWrap; color: "#6e6e6e"; font.pixelSize: 10; font.weight: Font.Normal
                        text: "Old package files kept so you can downgrade. Cleaning keeps the last two versions of each (it also happens by itself weekly)." }
            }
            SetButton { icon: "\u{f00e2}"; text: "Clean cache"; onClicked: pg.term("sudo paccache -rk2 && sudo paccache -ruk0") }
        }
        RowLayout {
            width: parent.width; spacing: 12
            Column {
                Layout.fillWidth: true; spacing: 6
                Label { text: pg.d.aur.length + " from the AUR"; font.pixelSize: 12 }
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: pg.d.aur
                        Rectangle { required property string modelData; width: al.implicitWidth + 18; height: 24; radius: 12; color: "#1a1a1a"
                                    Label { id: al; anchors.centerIn: parent; text: modelData; color: "#c8c8c8"; font.pixelSize: 10 } }
                    }
                }
            }
        }
    }

    SetSection {
        width: parent.width; title: "Biggest · " + pg.gb(pg.d.totalBytes) + " in all"; icon: "\u{f0a0a}"
        Repeater {
            model: pg.d.biggest
            RowLayout {
                required property var modelData
                width: parent.width; spacing: 12
                Label { Layout.preferredWidth: 200; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 11 }
                Rectangle {
                    Layout.fillWidth: true; height: 5; radius: 3; color: "#1fffffff"
                    Rectangle { height: 5; radius: 3; color: "#e0e0e0"; width: Math.max(5, parent.width * modelData.bytes / Math.max(1, pg.d.biggest[0].bytes)) }
                }
                Label { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: pg.gb(modelData.bytes); color: "#8a8a8a"; font.pixelSize: 10 }
            }
        }
    }

    SetSection {
        width: parent.width; title: "This week · " + pg.d.changes.length + (pg.d.changes.length >= 40 ? "+" : "") + " changes"; icon: "\u{f06b0}"
        Repeater {
            model: pg.showAll ? pg.d.changes : pg.d.changes.slice(0, 10)
            RowLayout {
                required property var modelData
                width: parent.width; spacing: 12
                Rectangle { width: 7; height: 7; radius: 4; color: modelData.what === "removed" ? "#cf6b6b" : modelData.what === "installed" ? "#ffffff" : "#8a8a8a" }
                Label { Layout.preferredWidth: 230; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 11 }
                Label { Layout.fillWidth: true; elide: Text.ElideLeft; text: modelData.ver; color: "#7a7a7a"; font.pixelSize: 10 }
                Label { text: modelData.what + "  ·  " + modelData.when; color: "#5a5a5a"; font.pixelSize: 9 }
            }
        }
        Label { visible: pg.d.changes.length === 0; text: "Nothing changed this week."; color: Theme.muted; font.pixelSize: 11 }
        Label { visible: pg.d.changes.length > 10; text: pg.showAll ? "Show less" : "Show all " + pg.d.changes.length; color: Theme.blue; font.pixelSize: 11
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.showAll = !pg.showAll } }
    }
}
