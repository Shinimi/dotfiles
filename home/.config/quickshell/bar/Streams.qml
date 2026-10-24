// Who is using sound, the mic, the camera or the screen right now (from PipeWire). Feeds the per-app volume
// sliders, the privacy dot on the bar and auto-pause. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream)
    PwObjectTracker { objects: root.streams }

    function prop(n, k) { return n && n.properties ? (n.properties[k] || "") : "" }
    function appName(n) { return prop(n, "application.name") || prop(n, "application.process.binary") || prop(n, "node.name") || "app" }
    function appIcon(n) { return prop(n, "application.icon-name") || prop(n, "application.process.binary").toLowerCase() || "audio-x-generic" }
    // our own plumbing (EQ, clean mic, meters, the shell itself) never counts as an "app"
    function ours(n) {
        const s = (prop(n, "node.name") + " " + appName(n) + " " + prop(n, "application.process.binary")).toLowerCase()
        return /effect_|clean_mic|headset_eq|cava|quickshell|\bqs\b|pavucontrol|volume control|peak|pw-play|paplay|kocho|wireplumber|gpu-screen-recorder|gsr/.test(s)
    }
    function cls(n) { return prop(n, "media.class") }

    // playback, one entry per app: { name, icon, nodes: [...] }
    readonly property var apps: {
        const by = {}
        for (const n of streams) {
            if (cls(n) !== "Stream/Output/Audio" || !n.audio || ours(n)) continue
            const k = appName(n)
            if (!by[k]) by[k] = { name: k, icon: appIcon(n), nodes: [] }
            by[k].nodes.push(n)
        }
        return Object.values(by).sort((a, b) => a.name.localeCompare(b.name))
    }
    function appVolume(a) { return a.nodes.length ? a.nodes[0].audio.volume : 0 }
    function appMuted(a) { return a.nodes.length ? a.nodes[0].audio.muted : false }
    function setAppVolume(a, v) { for (const n of a.nodes) { n.audio.muted = false; n.audio.volume = v } }
    function toggleAppMute(a) { const m = !appMuted(a); for (const n of a.nodes) n.audio.muted = m }

    // privacy: apps holding the mic, the camera, or a screen share
    readonly property var micUsers: [...new Set(streams.filter(n => cls(n) === "Stream/Input/Audio" && !ours(n)).map(appName))]
    readonly property bool screenShared: Pipewire.nodes.values.some(n => cls(n) === "Video/Source" && /xdph|screencast|portal/i.test(prop(n, "node.name") + prop(n, "media.name")))
    readonly property var videoUsers: [...new Set(streams.filter(n => cls(n) === "Stream/Input/Video" && !ours(n)).map(appName))]
    readonly property bool micLive: micUsers.length > 0
    readonly property bool anyLive: micLive || screenShared || videoUsers.length > 0
}
