// Settings → Default apps: what opens links, folders, pictures, videos… Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects

Column {
    id: pg
    spacing: 14
    property var cats: []
    Process {
        running: pg.visible
        command: ["python3", "-I", Qt.resolvedUrl("sysinfo.py").toString().replace("file://", ""), "defaults"]
        stdout: StdioCollector { onStreamFinished: { try { pg.cats = JSON.parse(this.text) } catch (e) {} } }
    }
    Label { visible: pg.cats.length === 0; text: "Looking at your apps…"; color: Theme.muted }
    Repeater {
        model: pg.cats
        SetSection {
            id: cs
            required property var modelData
            width: pg.width; title: modelData.label
            icon: ({ browser: "\u{f059f}", files: "\u{f024b}", images: "\u{f02e9}", video: "\u{f0567}", music: "\u{f075a}", text: "\u{f09ee}", pdf: "\u{f0226}", archive: "\u{f0187}" })[modelData.id] || "\u{f03d6}"
            Flow {   // each app as a tile with its icon; the picked one is white
                width: parent.width; spacing: 8
                readonly property string cur: (Settings.get("default_apps") || {})[cs.modelData.id] || cs.modelData.current
                Repeater {
                    model: cs.modelData.options
                    Rectangle {
                        id: ap
                        required property var modelData
                        readonly property bool on: parent.cur === modelData.id
                        readonly property string ico: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                        width: 112; height: 86; radius: 14
                        color: on ? "#ececec" : apm.containsMouse ? "#1c1c1c" : "#0f0f0f"; border.width: 1; border.color: on ? "#ececec" : "#222222"
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Item {
                            x: 12; y: 12; width: 30; height: 30
                            IconImage { id: aic; anchors.fill: parent; source: ap.ico; visible: false }
                            MultiEffect { anchors.fill: aic; source: aic; visible: ap.ico !== ""; saturation: ap.on ? 0 : -1; opacity: ap.on ? 1 : 0.85 }
                            Text { visible: ap.ico === ""; anchors.centerIn: parent; text: "\u{f003b}"; color: ap.on ? "#0b0b0b" : "#8a8a8a"; font.family: Theme.font; font.pixelSize: 22 }
                        }
                        Text { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: parent.width - 24; elide: Text.ElideRight
                               text: ap.modelData.name; color: ap.on ? "#0b0b0b" : "#d8d8d8"; font.family: Theme.font; font.pixelSize: 11; font.bold: ap.on }
                        MouseArea { id: apm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const d = Object.assign({}, Settings.get("default_apps")); d[cs.modelData.id] = ap.modelData.id; Settings.set("default_apps", d) } }
                    }
                }
            }
        }
    }
}
