// Settings → About & updates: the list of waiting updates. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

SetSection {
    id: pg
    title: busy ? "Updates · checking…" : (list.length ? "Updates · " + list.length + " waiting" : "Updates · up to date"); icon: "\u{f06b0}"
    property var list: []
    property bool busy: false
    property bool showAll: false
    property int tries: 0
    Timer { id: retry; interval: 4000; onTriggered: load.running = true }   // the bar may be checking at the same moment
    Process {
        id: load
        running: pg.visible
        onRunningChanged: pg.busy = running
        command: ["python3", "-I", Qt.resolvedUrl("sysinfo.py").toString().replace("file://", ""), "updates"]
        stdout: StdioCollector { onStreamFinished: { try { pg.list = JSON.parse(this.text) } catch (e) {} if (pg.list.length === 0 && Updates.total > 0 && pg.tries++ < 3) retry.restart() } }
    }
    Repeater {
        model: pg.showAll ? pg.list : pg.list.slice(0, 6)
        Row {
            required property var modelData
            width: parent.width; spacing: 10
            Label { width: parent.width * 0.42; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 12 }
            Label { width: parent.width * 0.42; elide: Text.ElideLeft; text: modelData.from + "  →  " + modelData.to; color: Theme.muted; font.pixelSize: 11 }
            Label { text: modelData.src; color: modelData.src === "AUR" ? Theme.purple : Theme.blue; font.pixelSize: 10 }
        }
    }
    Label {   // never an empty box: say what's going on
        visible: pg.list.length === 0; width: parent.width; color: Theme.muted; font.pixelSize: 11
        text: pg.busy ? "Looking for updates in the repos and the AUR…" : "\u{f012c}  Everything is up to date"
    }
    Label { visible: pg.list.length > 6; text: pg.showAll ? "Show less" : "Show all " + pg.list.length; color: Theme.blue; font.pixelSize: 11
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.showAll = !pg.showAll } }
}
