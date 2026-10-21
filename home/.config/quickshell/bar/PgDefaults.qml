// Settings → Default apps: what opens links, folders, pictures, videos… Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Io

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
            SetChoice {
                label: ""; accent: Theme.blue
                current: (Settings.get("default_apps") || {})[cs.modelData.id] || cs.modelData.current
                options: cs.modelData.options.map(o => [o.id, o.name])
                onPicked: v => { const d = Object.assign({}, Settings.get("default_apps")); d[cs.modelData.id] = v; Settings.set("default_apps", d) }
            }
        }
    }
}
