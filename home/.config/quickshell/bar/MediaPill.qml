// Now playing (shows only when something plays); click for the media panel. Made by Claude.
import QtQuick
import Quickshell.Services.Mpris

Pill {
    id: pill
    property alias popup: panel
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.identity === "Spotify") || players[0] || null
    visible: Settings.cur("bar_media") && player !== null && player.trackTitle !== ""
    active: panel.visible
    Label { text: pill.player && pill.player.isPlaying ? "\u{f075a}" : "\u{f03e4}"; color: Theme.fg; font.pixelSize: 13 }
    Label {
        text: pill.player ? pill.player.trackTitle + (pill.player.trackArtist ? "  ·  " + pill.player.trackArtist : "") : ""
        elide: Text.ElideRight; width: Math.min(implicitWidth, 240); color: Theme.fgDim; font.weight: Font.Normal
    }
    onClicked: m => { if (m.button === Qt.MiddleButton && player) player.togglePlaying(); else panel.toggle() }
    onScrolled: d => { if (player) (d > 0 ? player.next() : player.previous()) }
    MediaPopup { id: panel; anchorItem: pill; player: pill.player }
}
