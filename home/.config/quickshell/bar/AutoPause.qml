// Auto-pause: Spotify pauses when a call starts (an app opens the mic) or another player starts playing
// (a video in the browser), and picks up again 3 s after that ends. It only resumes music it paused itself,
// and if you press play during the call it leaves you alone. Settings → Comfort. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: root
    readonly property bool enabled: Settings.cur("auto_pause") !== false
    readonly property var spotify: Mpris.players.values.find(p => p.identity === "Spotify") || null
    readonly property bool otherPlaying: Mpris.players.values.some(p => p !== root.spotify && p.isPlaying)
    readonly property bool busy: enabled && (Streams.micLive || otherPlaying)
    property bool pausedByUs: false
    property bool leaveAlone: false      // you pressed play yourself during the call / video

    onBusyChanged: {
        if (busy) {
            resume.stop()
            if (spotify && spotify.isPlaying && !leaveAlone) { spotify.pause(); pausedByUs = true }
        } else resume.restart()
    }
    Timer {
        id: resume; interval: 3000
        onTriggered: {
            if (root.busy) return
            if (root.pausedByUs && root.spotify && !root.spotify.isPlaying) root.spotify.play()
            root.pausedByUs = false; root.leaveAlone = false
        }
    }
    Connections {
        target: root.spotify
        function onIsPlayingChanged() {   // you took over: don't fight you
            if (root.busy && root.spotify.isPlaying) { root.pausedByUs = false; root.leaveAlone = true }
        }
    }
}
