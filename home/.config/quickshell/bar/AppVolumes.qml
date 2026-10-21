// Per-app volume sliders (one per app, controlling all of its audio streams). Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Column {
    id: root
    width: parent ? parent.width : 300
    spacing: 8
    // app playback streams (Quickshell marks them isStream + isSink); mic captures are excluded
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio && !(n.name || "").startsWith("effect_"))
    PwObjectTracker { objects: root.streams }

    // group streams by application name
    readonly property var apps: {
        const g = {}
        for (const s of streams) {
            const p = s.properties || {}
            const raw = p["application.name"] || s.name || s.description || "Unknown"
            const name = raw.charAt(0).toUpperCase() + raw.slice(1)
            if (!g[name]) g[name] = { name: name, icon: p["application.icon-name"] || raw.toLowerCase(), nodes: [] }
            g[name].nodes.push(s)
        }
        return Object.values(g).sort((a, b) => a.name.localeCompare(b.name))
    }
    // apps whose stream name doesn't match their launcher
    readonly property var aliases: ({ "spotify": "spotify-launcher", "ue4": "steam", "ue5": "steam", "librewolf": "librewolf" })
    function iconFor(app) {
        const key = app.icon.toLowerCase()
        if (aliases[key]) { const a = Quickshell.iconPath(aliases[key], true); if (a) return a }
        const e = DesktopEntries.heuristicLookup(app.icon) || DesktopEntries.heuristicLookup(app.name)
        return Quickshell.iconPath(e && e.icon ? e.icon : app.icon, true) || Quickshell.iconPath("audio-volume-high")
    }
    function label(name) { return name === "UE4" || name === "UE5" ? "Game" : name }

    Label { visible: root.apps.length > 0; text: "Apps"; color: Theme.muted; font.pixelSize: 11 }
    Repeater {
        model: root.apps
        RowLayout {
            required property var modelData
            readonly property var lead: modelData.nodes[0]
            readonly property bool muted: lead && lead.audio ? lead.audio.muted : false
            width: root.width; spacing: 10
            Rectangle {
                width: 32; height: 32; radius: 9
                color: muted ? Theme.red : (aMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
                IconImage { anchors.centerIn: parent; implicitSize: 20; source: root.iconFor(modelData); opacity: muted ? 0.4 : 1 }
                MouseArea { id: aMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { const m = !muted; for (const n of modelData.nodes) if (n.audio) n.audio.muted = m } }
            }
            Column {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                    width: parent.width
                    Label { text: root.label(modelData.name); font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: lead && lead.audio ? Math.round(lead.audio.volume * 100) + "%" : ""; color: Theme.muted; font.pixelSize: 10 }
                }
                Slider {
                    accent: Theme.blue
                    value: lead && lead.audio ? Math.min(1, lead.audio.volume) : 0
                    onMoved: v => { for (const n of modelData.nodes) if (n.audio) { n.audio.muted = false; n.audio.volume = v } }
                }
            }
        }
    }
}
