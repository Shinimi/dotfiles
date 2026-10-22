// Record player on the desktop (behind windows, bottom-right): the album art spins on a vinyl while
// music plays, the tonearm lifts when you pause. Settings → Extras. Made by Claude.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: w
    required property var modelData
    screen: modelData
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify" && p.trackTitle) || null
    readonly property bool playing: !!(player && player.isPlaying)
    property string art: ""
    readonly property string liveArt: player ? (player.trackArtUrl || "") : ""
    onLiveArtChanged: if (liveArt !== "") art = liveArt   // never hand Image an empty source (Qt 6.12 crash)

    visible: Settings.cur("desktop_vinyl") && player !== null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qsbar-desktop"
    color: "transparent"
    anchors { right: true; bottom: true }
    margins { right: 70; bottom: 70 }
    implicitWidth: row.implicitWidth; implicitHeight: row.implicitHeight
    mask: Region {}   // purely decorative: clicks go to the desktop

    Row {
        id: row
        spacing: 26; layoutDirection: Qt.RightToLeft
        Vinyl { art: w.art; playing: w.playing; size: 200 }
        Column {
            anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Text { anchors.right: parent.right; width: Math.min(implicitWidth, 380); elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                   text: w.player ? w.player.trackTitle : ""; color: Theme.fg; font.family: Theme.font; font.pixelSize: 20; font.bold: true
                   style: Text.Raised; styleColor: "#aa000000" }
            Text { anchors.right: parent.right; width: Math.min(implicitWidth, 380); elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
                   text: w.player ? (w.player.trackArtist || w.player.identity) : ""; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 14
                   style: Text.Raised; styleColor: "#aa000000" }
            Text { anchors.right: parent.right; text: w.playing ? "now playing" : "paused"; color: Theme.muted; font.family: Theme.font
                   font.pixelSize: 11; font.letterSpacing: 3; topPadding: 6; style: Text.Raised; styleColor: "#aa000000" }
        }
    }
}
